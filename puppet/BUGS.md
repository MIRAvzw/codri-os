Major
=====

Multiple CRON runs
------------------

If cron minute changes from x to y with y>x, cron will run another time.

Log:
> May  4 03:20:06 efikamx-9ba3b8 puppet-agent[18163]: Reopening log files  
> May  4 03:20:19 efikamx-9ba3b8 puppet-agent[18163]: (/Stage[essential]/Repository/Apt::Key[repository@codri.local.key]/Exec[apt-key present repository@codri.local.key]/returns) executed successfully  
> May  4 03:21:16 efikamx-9ba3b8 puppet-agent[18163]: (/Stage[essential]/Repository/Exec[update]/returns) executed successfully  
> May  4 03:21:25 efikamx-9ba3b8 puppet-agent[18163]: (/Stage[services]/Puppet/Cron[puppet]/minute) minute changed '20' to '33'  
> May  4 03:21:31 efikamx-9ba3b8 puppet-agent[18163]: Finished catalog run in 74.96 seconds  
> May  4 03:33:07 efikamx-9ba3b8 puppet-agent[18899]: Reopening log files  
> May  4 03:33:19 efikamx-9ba3b8 puppet-agent[18899]: (/Stage[essential]/Repository/Apt::Key[repository@codri.local.key]/Exec[apt-key present repository@codri.local.key]/returns) executed successfully  
> May  4 03:33:36 efikamx-9ba3b8 puppet-agent[18899]: (/Stage[essential]/Repository/Exec[update]/returns) executed successfully  
> May  4 03:33:45 efikamx-9ba3b8 puppet-agent[18899]: (/Stage[services]/Puppet/Cron[puppet]/minute) minute changed '33' to '55'  
> May  4 03:33:51 efikamx-9ba3b8 puppet-agent[18899]: Finished catalog run in 34.97 seconds  
> May  4 03:55:06 efikamx-9ba3b8 puppet-agent[19771]: Reopening log files  
> May  4 03:55:18 efikamx-9ba3b8 puppet-agent[19771]: (/Stage[essential]/Repository/Apt::Key[repository@codri.local.key]/Exec[apt-key present repository@codri.local.key]/returns) executed successfully  
> May  4 03:55:46 efikamx-9ba3b8 puppet-agent[19771]: (/Stage[essential]/Repository/Exec[update]/returns) executed successfully  
> May  4 03:55:55 efikamx-9ba3b8 puppet-agent[19771]: (/Stage[services]/Puppet/Cron[puppet]/minute) minute changed '55' to '29'  
> May  4 03:56:01 efikamx-9ba3b8 puppet-agent[19771]: Finished catalog run in 45.35 seconds  



Minor
=====

Botched NoDM start
------------------

Due to crappy NoDM init scripts, we need to invoke nodm restart in a special
manner, or /var/run/nodm.pid gets corrupt.

Sometimes happens when manually restarting NoDM too.
