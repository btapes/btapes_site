#Hugo Nginx server on Raspberry 3

## Installing the server and firewall

First, install the Nginx server, as well as UFW for a simple firewall.

`sudo apt install nginx ufw`

Set up the firewall
Before doing anything, if you’re accessing the server via SSH, you should allow such traffic prior to enabling the firewall. Otherwise, you’ll lock yourself out of the server and we don’t want that. Assuming we’re using the default SSH port (22):

sudo ufw allow 22
$ sudo ufw reload
If everything went right, you should still be in the server in your SSH session. Now, to allow traffic for the Nginx server, run:

$ sudo ufw allow 'Nginx Full'
$ sudo ufw reload
This will allow traffic on ports 80 and 443. Every time you change firewall rules, you need to run reload to get UFW to apply the rules. You can check the status of the firewall by running:


We had to disable the firewall in order to make it work


$ sudo ufw status
For a short tutorial on using UFW, check out this page.

Set up the Nginx server
Initial setup
To start the server, simply run:

$ sudo systemctl start nginx
Type in your server’s IP address in a browser. If it’s working properly, you should be able to see a generic Nginx page. By default, Nginx stores the data for the webserver in /var/www/. You can use this location or any other for your server. We will be using that one for this example.

To set up the new server, create a new file in /etc/nginx/sites-available with the name of your new server using whichever text editor you fancy. We’ll call it example.com:

$ sudo emacs /etc/nginx/sites-available/example.com
Now, paste in the following configuration, changing the appropriate values:

server {
    listen 80; # Configure the server for HTTP on port 80
    server_name example.com; # Your domain name
    root /var/www; # The files for your server
    index index.html; # You will create this file shortly
}
Copy
The server block defines the parameters for the server. This is a pretty barebones configuration, but it will suffice for our webpage.

In order to serve content, you must have something to send to the clients connecting to your website. Right now, you only have the default Nginx page in your www directory, or nothing at all if you are using something other than /var/www/. If you created a new www directory, make sure Nginx can read it by running:

$ sudo chmod 0755 /your/path/to/www
Now, let’s create the index.html file we defined:

$ sudo emacs /var/www/index.html
In it, write any text you want. For example:

If you can see this, the webserver is working!
To tell Nginx to run your new webserver, you must add it to /etc/nginx/sites-enabled by running:

You have to delete the default page in order to make it work

$ sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
Restart the Nginx server by running:

$ sudo systemctl restart nginx
If you did everything correctly, you should be able to see the text you put into index.html by typing your domain in any browser. If you’re running it locally, you might have to point your domain to the local IP of the server in your /etc/hosts file.

For more information on Nginx, check out the official documentation.


Set up SSL (HTTPS)
We’ll be using a free certificate from Let’s Encrypt to set up SSL on our server. Install the certificate bot:

$ sudo apt install python-certbot-nginx
Now, run the bot:

$ sudo certbot --nginx
When prompted, select your domain and then tell the bot to redirect all HTTP traffic to HTTPS. If it works properly, the bot will let you know. Restart the Nginx server:

$ sudo systemctl restart nginx
Now, if you visit your webserver on any browser, you should be automatically redirected to the SSL version of the site. To ensure the certificate is renewed automatically, edit your crontab:

$ sudo crontab -e
Add the following line to run the bot at 09:00 every day.

0 9 * * * certbot renew --post-hook "systemctl reload nginx"
Feel free to change the time to whichever works best for you. First column specifies the minutes and the second specifies the hour (24h clock).

Note: Because we’re using SSL, enabling gzip compression might introduce a security vulnerability. Therefore, we will skip this step. However, if you’re certain no sensitive information is being transmitted, here’s a simple guide to enabling it.

Additional configuration
Enable HTTPS/2
HTTPS/2 is, in essence, a better version of HTTPS that brings performance improvements for your page. To enable it, simply edit your configuration file:

$ sudo emacs /etc/nginx/sites-available/example.com
You will see a bunch of changes done by CertBot to enable SSL. We’re interested in the following line:

listen 443 ssl; # managed by Certbot
Change that to:

listen 443 ssl http2; # managed by Certbot
Restart the Nginx server to enable your changes.

Enable client-side caching
Given that resources like images and videos don’t change all that often, it’s not necessary to make clients fetch them every time they load the page. To enable caching, edit your configuration file:

$ sudo emacs /etc/nginx/sites-available/example.com
And add the following at the end of the first server block:

server{
    # ...
    # Stuff
    # ...

    # Media
    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|mp4|ogg|ogv|webm|htc)$ {
        expires 30d;
    }

    # CSS and Js
    location ~* \.(css|js)$ {
        expires 7d;
    }
Copy
CSS and Js files have a lower expiration date since they are more prone to being changed than media files.

Your server is now ready to serve a website.

Creating the website with Hugo
The great thing about Hugo is that it lets you create simple, static webpages that are faster and more secure than dynamic webpages. Additionally, these websites work great in any device: whether you’re on your computer with a big monitor or on a cellphone, they scale very well. With Hugo, building the site and adding content to it is a breeze.

You can install Hugo on your server, but the way I do it is in my development machine. To install:

$ sudo apt install hugo
Create your new website by running:

$ hugo newsite sitename
Replace sitename with whatever you want to name your site. Go to themes.hugo.io to choose a theme for your site. Now, go into the sitename directory and download the theme as indicated using git. This page uses the Hermit theme, so we’ll download that one:

$ git clone https://github.com/Track3/hermit.git themes/hermit
To enable the theme, we add the following line to the config.toml file in the root sitename directory:

theme = 'hermit'
In order to configure the site as you like, most themes have a guide to doing so in the page where you got it from. In addition, they tend to have an example site to guide you. Our theme, Hermit, has a nicely commented configuration file in themes/hermit/exampleSite, as well as a few example posts.

To create a new post, run:

$ hugo new posts/some-post.md
The posts are written using Markdown. If you’re not familiar with it, check out this quick start guide. Our theme, Hermit, also includes a bunch of information on Markdown usage in its sample posts. To build and run the page locally, go to the sitename directory and type:

$ hugo server -D
This runs a local webserver, enabling drafts with the -D option. For more information on this, check out the basic usage page for Hugo. The website will automatically reload as you edit the posts, so you don’t have to stop and reload the server whenever you change content. Once you’re happy with the site, in the sitename directory run:

$ hugo
This will build the site under sitename/public. These are the files we need to send to the server to run. If this is the first time you upload the site to the server, delete anything in your www folder before continuing.

Since in our example, the server is running in a remote machine, we will send over the site via rsync. To do so, we run:

$ rsync -aAXv /path/to/sitename/public/ user@example.com:/var/www/ --delete
This assumes that our user has write permissions to the www directory on the remote machine, that our domain is example.com and that we left the SSH port enabled. Otherwise, this will not work. Adjust depending on your setup.

To enable the usage of the custom 404 landing page in your Hugo theme, instead of the default Nginx page, add this line to your first server block in the configuration file for your site (/etc/nginx/sites-available/yoursite.com):

error_page 404 /404.html;
Finally, if you go to your site by typing in the address in any browser (example.com in our example), you should be able to see your page!

For more information on Hugo, visit the official documentation.

WebLinux

1556 Words

2020-06-13 15:40 -0500

 NEWER
Simple application sandboxing using AppArmor and Firejail
© 2020 Piero Vera · CC BY-NC 4.0

Made with Hugo · Theme Hermit · 