## 2.16.10

 - **FIX**: android connectivity.

## 2.16.9

 - **FIX**: calculate waiting time based on data size on android.

## 2.16.8

 - **FIX**: print image.

## 2.16.7

 - **FIX**: Android crash on call connect().
 - **FIX**: iOS connect return false even it's connected.

## 2.16.6

 - **FIX**: obsolete printer status.

## 2.16.5

 - **FIX**: revert to printImageSingle instead of splits image into chunks.
 - **FIX**: crash when turn on bluetooth on android.

## 2.16.4

 - **FIX**: ios and android print.

## 2.16.3

 - **FIX**: print image in chunks.

## 2.16.2

 - **FIX**: reduce dot per lines.

## 2.16.1

 - **FIX**: clear buffers before printing.

## 2.16.0

 - **FEAT**: improve connection.

## 2.15.4

 - **FIX**: improve raster image.

## 2.15.3

 - **FIX**: improve print speed.

## 2.15.2

 - **FIX**: ios, return false if failed to print.

## 2.15.1

 - **FIX**: return bool receipt controller.print.

## 2.15.0

 - **FEAT**: return boolean for write result.

## 2.14.2

 - **FIX**: font style.

## 2.14.1

 - **FIX**: receipt text style.

## 2.14.0

 - **FEAT**: expose maxBuffersize and delayTime.

## 2.13.0

 - **FEAT**: added containerBuilder to custom receipt layout.

## 2.12.4

 - **FIX**: black print.

## 2.12.3

 - **FIX**: encode to jpg.

## 2.12.2

 - **FIX**: image raster.
 - **FIX**: lints.

## 2.12.1

 - **REFACTOR**: improve image process.
 - **FIX**: useImageRaster.

## 2.12.0

 - **FEAT**: change default receipt font to jetbrains-mono.

## 2.11.2

 - **FIX**: duplicated class.

## 2.11.1

 - **DOCS**: update LICENSE.

## 2.11.0

 - **FEAT**: added macos.

## 2.10.0

 - **FEAT**: remove esc_pos_utils dependencies.

## 2.9.1

 - **FIX**: improve print speed android.

## 2.9.0

 - **FEAT**: [android] split payload into chunks.

## 2.8.2

 - **FIX**: receipt print.

## 2.8.1

 - **FIX**: update dependencies.

## 2.8.0

 - **FEAT**: updated image dependency version constraint.

## 2.7.1

 - **FIX**: updated UUID.

## 2.7.0

 - **FEAT**: added support keepConnected.

## 2.6.3

 - **DOCS**: fix typo.

## 2.6.2

 - **DOCS**: updated README.md.

## 2.6.1

 - **PERF**: improve receipt.
 - **PERF**: optimizing recipt in a background isolate.

## 2.6.0

 - **FEAT**: determine chunkSize dynamically.

## 2.5.0

 - **FEAT**: added option to useImageRaster while print.

## 2.4.0

 - **FEAT**: reimplements ios native platform.
 - **FEAT**: improve receipt widget.

## 2.3.0

 - **FEAT**: imrpove state ios.
 - **FEAT**: improve state (android).

## 2.2.3

 - **FIX**: android 10 permission.

## 2.2.2

 - **FIX**: double discovered devices.

## 2.2.1

 - **FIX**: multiple same device on discovery.
 - **FIX**: pubspec.lock.

## 2.2.0

 - **REFACTOR**: refactor.
 - **FIX**: update readme.
 - **FEAT**: added BusyDeviceException.

## 2.1.0

 - **FEAT**: added device selector and allow receipt widget.

## 2.0.0

* 2022-07-08: Simplify usages

## 1.1.10

* 2022-01-11: check bluetooth permission [iOS] on start scan
## 1.1.9

* 2021-12-09: fix Image?
## 1.1.8

* 2021-11-04: fix java code
## 1.1.7

* 2021-11-03: added getDevice by address method
## 1.1.6

* 2021-10-31: retrieve bonded devices on android
## 1.1.5

* 2021-10-30: refactor objc code
## 1.1.4

* 2021-09-25: remove dotsPerLine
## 1.1.3

* 2021-09-25: improve printing
## 1.1.2

* 2021-09-14: fix freeze on android
## 1.1.1

* 2021-09-14: added isConnected and getConnectedDevice
## 1.1.0+1

* 2021-09-13: Fix method name in android.
## 1.1.0

* 2021-09-13: Add support for iOS.
## 1.0.3

* 2021-09-13: Update description.
## 1.0.2

* 2021-09-12: Change printBytes to printCommands.
## 1.0.1

* 2021-09-12: Added support for iOS experimentally.
## 1.0.0

* 2021-09-12: Initial release.
