# homebridge-config-backup.sh
This is a bash script that allows you to automate local backup of *config.json* of a Homebridge instance runing inside a Docker container.

With v1.2.0, this script implements unix-like command structure, so if you want to use a working directory different from default one, you must use ***-d*** option along with the path to that directory.

Things to do after dowloading script

- Make shell script executable runing "chmod u+x homebridge-config-backup.sh"
- Edit cron with "crontab -e" command and add the subsequent line at the end, replacing *<abs_path>* with the location where you stored *homebridge-config-backup.sh*, and *<working_directory>* with the directory where backups will be stored, without *$HOME* path.

  >  0 * * * * bash /<abs_path>/homebridge-config-backup.sh -d <working_directory>
  
- Save cron using Ctrl-O
- Exit editor with Ctrl-X
- Reboot so changes take effect

The cron example will run the script every hour. The script will attempt to copy *config.json* from Homebridge docker container to local storage, check if md5sum of copied file and existing backup are equal or different. If md5sum is different, the script will create a backup including md5sum in the name of the file, and write down the result of the task on a log file, so you can check the timeline of all the backups.

Obviously you can change the time interval at wich the script runs modifying the cron command. I recomend https://crontab.guru to do that.
