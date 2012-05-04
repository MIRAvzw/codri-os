Short term
==========

Documentation
-------------

Port the dutch documentation to these scripts.


Kernel
------

Currently, our packaged kernel results in corrupt initrds. Ditch the initrd
altogether, or fix the initrd generation process.

Current Puppet "kernel" class is responsible for erasing the current static kernel, and
installing a update package.


Locale
-------


multistrap retainsources
------------------------


testing
-------

Move from unstable (sid) to testing (wheezy).


Long term
=========

Boot splash
-----------

* Plymouth for armhf?
* Base artwork on [Genesi's](https://github.com/genesi/genesi-artwork)


Accelerated software stack
--------------------------

NEON/OpenGL ES2/OpenVG/EGL accelerated versions of several packages:
* Chromium
* Qt
