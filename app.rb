# GVA IT SERVICES
# 21 septembre 2016
# Reporting GLPI - Tickets

require 'sinatra'
require 'sequel'
require 'date'
require 'pdfkit'
require 'zip'

set :root, File.dirname(__FILE__)

# Database parameters
@db_host = "localhost"
@db_user = "root"
@db_pass = "root"
@db_name = "GLPI"

DB = Sequel.connect(:adapter => 'mysql2', :host => @db_host, :username => @db_user,
                    :password => @db_pass, :database => @db_name, :cast => false)

ERROR_MESSAGE = [
    "Aucun ticket n'a été trouvé dans cette plage de date !",
    "La date de début ne peut-être plus récente que la date de fin !",
    "Veuillez sélectionner un ou plusieurs clients !"
]

get '/' do
  # Get all the customers to populate the multiselect menu
  @customers = DB.fetch("SELECT id, name FROM glpi_entities")
  @error = false
  erb :index
end

get '/:error' do
  # Get all the customers to populate the multiselect menu
  @customers = DB.fetch("SELECT id, name FROM glpi_entities")
  @error = true
  @error_message = ERROR_MESSAGE[params[:error].to_i]
  erb :index
end

post '/' do

  # We check that customers have been selected
  if params[:customers].to_a.length != 0

    # Get the forms parameters and parse them
    @start_date = Date.strptime(params[:start_date], '%m/%d/%Y').strftime('%Y-%m-%d')
    @end_date = Date.strptime(params[:end_date], '%m/%d/%Y').strftime('%Y-%m-%d')

    # We check if the selected dates are legit
    if @start_date < @end_date

      # Create to hash tables to store the all the customers and reports
      @reports = Hash.new
      @customers = Hash.new

      case params[:status]
        when 'resolved'
          @status = ' = 5'
        when 'closed'
          @status = ' = 6'
        when 'both'
          @status = ' >= 5'
      end

      # Foreach customers selected by the user, get the tickets and the tasks related
      params[:customers].to_a.each do |c|
        @tickets = DB.fetch("SELECT ticket.id, ticket.name, ticket.actiontime, user.alternative_email,
                            ticket.type, recipient.realname
                          FROM glpi_tickets AS ticket
                            LEFT OUTER JOIN glpi_tickets_users AS user
                              ON ticket.id = user.tickets_id
                            LEFT OUTER JOIN glpi_users AS recipient
                              ON  ticket.users_id_recipient = recipient.id
                          WHERE ticket.actiontime >  0
                            AND user.type = 1
                            AND ticket.entities_id =" + c + " AND ticket.solvedate BETWEEN '" + @start_date + "' AND '" +
                                @end_date + "'" + " AND ticket.status " + @status)

        # Get the name of the customer
        @customer = DB.fetch("SELECT name FROM glpi_entities WHERE glpi_entities.id =" + c).all

        # Get the SUM of all tickets
        @tasks_sum = DB.fetch("SELECT CAST(SUM(ticket.actiontime) AS UNSIGNED) as TOTAL_TIME
                          FROM glpi_tickets AS ticket
                            LEFT OUTER JOIN glpi_tickets_users AS user
                              ON ticket.id = user.tickets_id
                          WHERE ticket.actiontime >  0
                            AND user.type = 1
                            AND ticket.entities_id =" + c + " AND ticket.solvedate BETWEEN '" + @start_date + "' AND '" +
                                @end_date + "'" + " AND ticket.status " + @status)

        # Convert the total time in seconds in an hour:seconds:minute format
        t = @tasks_sum.to_a.first[:TOTAL_TIME].to_i
        mm, ss = t.divmod(60)
        hh, dd = mm.divmod(60)
        @total_time = "%02d:%02d:%02d" % [hh.to_s, dd.to_s, ss.to_s]

        # Store the html rendered with values in an array
        if @tickets.to_a.length > 0
          @reports[@customer.first[:name]] = erb :report
        else
          # ERROR CODE 0 - We didn't find any tickets
          DB.disconnect
          redirect to('/0')
        end
      end

      @file = Array.new
      time = Time.new

      # More than one report to process
      if @reports.length > 1

        # Generate reports
        @reports.each_key do |r|
          kit = PDFKit.new(@reports[r])
          @file << kit.to_file(File.dirname(__FILE__) + '/public/tmp/' + r + '_rapport_mensuel.pdf')
        end

        # Add reports to the zip file and send it
        zipfile_name = time.day.to_s + time.month.to_s + time.year.to_s + '_' + time.sec.to_s + '_reports.zip'
        zipfile_path = File.dirname(__FILE__) + '/public/tmp/' + zipfile_name
        Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
          @file.each do |f|
            zipfile.add(f.path.to_s.split('/').last, f)
          end
        end
        content_type 'application/zip'
        zip = File.join(zipfile_name, zipfile_path)
        DB.disconnect
        send_file(zipfile_path, :disposition => 'attachment')
      else
        # Only one report to process
        @reports.each_key do |r|
          kit = PDFKit.new(@reports[r])
	        @file << kit.to_file(File.dirname(__FILE__) + '/public/tmp/' + r + '_rapport_mensuel.pdf')
          content_type 'application/pdf'
          DB.disconnect
          send_file @file.first
        end
      end
    else
      # ERROR CODE 1 - startdate is plus récente than enddate
      DB.disconnect
      redirect to('/1')
    end
  else
    # ERROR CODE 2 - No customer selected
    DB.disconnect
    redirect to('/2')
  end
end
