# timemaster
a simple POSIX-compliant utility for comfortable time management
## Functionality
`timemaster` lets you record how much time you spend on different activities. Before we cover its features in more detail, let's mention a few keywords we'll be using:
- By **stage**, we mean a time period. You may for example want to begin new stages monthly.
- We will refer to the different actions you will be recording simply as **activities**.
- **Saving directory** is the directory where `timemaster` stores all its data.

*Less important facts will be written in italic. Note that in the code examples, timemaster is referred to as simply `tm`. It is recommended that you add timemaster to your `$PATH` as `tm`, or another short convenient label of your choice.*
## Features
Now, let's cover all the commands.
### help
`tm -h` and `tm --help` print a short rundown on `timemaster's` commands. Whenever you are not sure about the usage, you can use this.
### set
`tm set [saving directory]` lets you set the saving directory. You don't need to use this command if you don't want to reset it to another one, because you will be asked which directory to use if you don't set it before the first `start` or `begin`.
### begin
`tm begin [stage name]` sets the current stage name 

&nbsp;

*Timemaster stores all the settings in `~/tm.set`. Each stage has its data stored in a different file inside the saving directory.*
### start and stop
`tm start [activity]` and `tm stop [activity]` start and stop an activity.
If you don't want to waste your time on writing a 5 letter long word, you can use `tm s [activity]`*(lowercase s)* for start and `tm S [activity]`*(capital S)* for stop.
### recap
`tm recap [stage name]`, perhaps the most important command, prints how much time in total you spent on all activities during the selected stage (along with their *wages*, if any are set).

*If you don't specify the stage name, the current stage will be recapitulated.*
### status
`tm status` prints the current settings (in case you forget) and currently running activities.
### autostop and multi
If your goal is to continuously switch between activities, you may want to run the `tm autostop +` command, which will make timemaster stop all running activities when starting a new one *(cutting down the need to stop them manually)*.

If you want to be able to have multiple activities running at once, run the `tm multi +` command.

`tm autostop -` and `tm multi -` unset these settings.

Both these commands have a shorter version: `tm a+`, `tm a-`, `tm m+` and `tm m-`

*These options are disabled on default, which ensures that you don't leave any activity running when starting a new one.*
### wages
Timemaster also lets you set 'wages' for your activities. The syntax for that is `tm wage [activity name] [h/m/s] [wage value(integer)] [unit]`, where `h` means hour, `m` minute, and `s` second.

For example, if you want to reward yourself with a cookie for every hour of workout, you may run:
`tm wage workout h 1 cookies`
Or if you work from home and your salary is $2000 a second, you may run:
`tm wage work s 2000 USD`

As stated above, these settings than take effect when **recap**itulating a stage (your deserved wage will be printed along with the time you spent on the activity).

*Wages are not stage specific (they are stored in the `~/tm.set` config file), so you don't have to reset them every time you **begin** a new stage.*

&nbsp;

&nbsp;

**IMPORTANT NOTE: You should only use letters from the English alphabet for activity, stage, and unit names. Other characters are not permitted.**
