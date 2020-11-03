### CesiumOS's automated Jenkins script!

#### How does it work? It needs 5 arugments to be passed the the {console|user} to work. The example is mentioned below:

#### Ex: 

``` bash build.sh begonia OFFICIAL userdebug true true true ```

#### What does these arugments represent ?
begonia -> device codename <br />
OFFICIAL -> build type {OFFICIAL|BETA} are the possible args <br />
userdebug -> build debug type {eng, userdebug, user} are the possible args <br />
true -> Whether to sync the source code or not. {true|false} are the possible args <br />
true -> Whether to perform a clean build or not. {true|false} are the possible args <br />
true -> Whether to use ccache while building or not. {true|false} are the possible args <br />

#### That's all thank you for reading! 
