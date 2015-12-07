#PX Nginx Plugin
For futher information about the design and implemenation follow [the wiki page](https://perimeterx.atlassian.net/wiki/display/PD/Nginx+Plugin).

###Development
1. Required - Local docker environment
2. Follow:
	
		$ git clone https://github.com/PerimeterX/pxNginxPlugin && cd pxNginxPlugin
		$ bash deploy_nginx.sh
		
		
The deploy script will launch a docker container with nginx instace compile with lua-nginx-module and the plugin sources 



	

