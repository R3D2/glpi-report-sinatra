# GLPI - REPORT

## Description
In our company, we use GLPI has a tool to follow-up all incidents or request made by our clients. Each entity in GLPI
is a client in our case and i was asked to make a program who generates a summary of all the tickets resolved in a 
given range of dates.

### Home page
![screenshot](https://github.com/R3D2/glpi-report-sinatra/raw/master/docs/home_page.png)

### Report
![preview](https://github.com/R3D2/glpi-report-sinatra/raw/master/docs/report_example.pdf)


## Installation

### Database

Specify the right credentials to log into the GLPI database in the 'app.rb' file.

### Deploy
In our production environment we use Phusion passenger + apache, just follow the guidelines on the web. If you
want to use another web server feel free to remove the "config.ru" and the passenger gem from the dependencies.

In the public folder, you need to create a new folder called "tmp" and give write permissions. This folder is used
to generate the pdfs.

Keep in mind the program has been made with the objective of being deployed on a sub-folder /report at the root of the
 GLPI application. If you want to change that, you will need to change all the urls in the app.

## Usage

Select one or many entities, the time range and the status of the tickets you want to be displayed in the report and 
generate.

little help for non french speakers :
* résolu - resolved
* clos - closed

The look of the report can be easily changed by tweaking the 'report.erb' file.

## License

MIT License

Copyright R3 and other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
