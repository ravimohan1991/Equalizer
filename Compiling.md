Here we shall chalk out the steps to be taken for compiling the code base and the relevant changes/filling of the information 
based on the local necessacities of the build environment and all that.

- First make sure to fill the relevant ```Version``` and ```BuildNumber``` in the class ```Equalizer.uc```. For versioning, default scheme
is [Semantic Versioning](https://semver.org/). ```BuildNumber``` could be date-time format or my personal favourite the *literal* number of times
the Engine compiled the code! 
<ins>Note</ins>: In semantic versioning, there are periods as delimiters. We shall be excluding them while generating the ```Version``` string.
- Next fill up the ```LogCompanionTag``` field (in the same class). This is to identify the Equalizer related logs.
  ```
  Equalizer_some_super_duper_cool_Name: # Equalizer_TC_alpha1 (build: 20220129) Initialized! GLHF #
  ```
- Equalizer is open enough (well, besides being open-source) to allow the relevant hooking of [```UniqueIdentifier```](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/UniqueIdentifier.md) and [```TeamSizeBalancer```](https://github.com/ravimohan1991/Equalizer/blob/miasmactivity/Classes/TeamSizeBalancer.uc) (a private code hosted in [Miasma](https://miasma.rocks)). You may want to write relevant algorithms for them.

- Once that is done, we now compile the code such that the ```.u``` package generated be ```Version + BuildNumber``` (to avoid file mismatch). For instance if ```Version=_TC_alpha1```
and ```BuildNumber=20220129```, the the package name should be ```Equalizer_TC_alpha120220129```. Check out the equalizerrun.bat file in ```/Misc``` folder.
