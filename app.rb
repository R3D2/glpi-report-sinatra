# GVA IT SERVICES
# 21 septembre 2016
# Reporting GLPI - Tickets

require 'sinatra'
require 'sequel'
require 'date'
require 'pdfkit'
require 'zip'

# Database parameters
@db_host = "localhost"
@db_user = "root"
@db_pass = "root"
@db_name = "GLPI"

DB = Sequel.connect(:adapter => 'mysql2', :host => @db_host, :username => @db_user,
                    :password => @db_pass, :database => @db_name)

get '/' do

  # Get all the
  @customers = DB.fetch("SELECT id, name FROM glpi_entities")
  erb :index
end

post '/' do
  content_type 'application/pdf'

  # Month to be displayed in the report
  @fr_month = %w(Janvier Février Mars Avril Mai Juin Juillet Août Septembre Octobre Novembre Décembre)

  # Get the forms parameters and parse them
  @start_date = Date.strptime(params[:start_date], '%m/%d/%Y').strftime('%Y-%m-%d')
  @end_date = Date.strptime(params[:end_date], '%m/%d/%Y').strftime('%Y-%m-%d')

  # Create to hash tables to store the all the customers and
  # reports
  @reports = Hash.new
  @customers = Hash.new

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
                           @end_date + "'" + " AND ticket.status >= 5")
    # Get the name of the customer
    @customer = DB.fetch("SELECT name FROM glpi_entities WHERE glpi_entities.id =" + c).all

    # Get the SUM of all tickets
    @tasks_sum = DB.fetch("SELECT SEC_TO_TIME(SUM(ticket.actiontime)) as TOTAL_TIME
                          FROM glpi_tickets AS ticket
                            LEFT OUTER JOIN glpi_tickets_users AS user
                              ON ticket.id = user.tickets_id
                          WHERE ticket.actiontime >  0
                            AND user.type = 1
                            AND ticket.entities_id =" + c + " AND ticket.solvedate BETWEEN '" + @start_date + "' AND '" +
                              @end_date + "'" + " AND ticket.status >= 5")

    # Store the html rendered with values in an array
    if @tasks_sum != nil
      @reports[@customer.first[:name]] = erb :report
    else
      render
    end

  end

  @file = Array.new
  time = Time.new

  # More than one report to process
  if (@reports.length > 1)

    # Generate reports
    @reports.each_key do |r|
      kit = PDFKit.new(@reports[r])
      @file << kit.to_file(File.dirname(__FILE__)  + '/public/tmp/' + r + '_rapport_mensuel.pdf')
    end

    # Add reports to the zip file and send it
    zipfile_name = File.dirname(__FILE__)  + '/public/tmp/' + time.day.to_s + time.month.to_s + time.year.to_s + '_' + time.sec.to_s + '_reports.zip'
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      @file.each do |f|
        zipfile.add(f.path.to_s.split('/').last, f)
      end
    end
    send_file zipfile_name
  else
    # Generate reports
    @reports.each_key do |r|
      kit = PDFKit.new(@reports[r])
      @file << kit.to_file(File.dirname(__FILE__)  + '/public/tmp/' + r + '_rapport_mensuel.pdf')
      send_file @file.first
    end
  end
end