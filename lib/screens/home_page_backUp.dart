import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:ndialog/ndialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blinking_text/blinking_text.dart';

import '../utils/clockControlButton.dart';
import '../screens/settingsPage.dart';
import '../utils/settingsSharedPreferences.dart';
import '../notification/localNotifications.dart';
import '../utils/dialog_action_button.dart';
import '../notification/alarm_manager_foreground.dart';
import '../utils/timerSyncHandler.dart';
//import '../notification/flutter_foreground_task.dart';
import '../utils/helper.dart';

class HomePage extends StatefulWidget {
  final List<Icon> timesCompleted = [];

  HomePage() {
    for (var i = 0; i < 3; i++) {
      timesCompleted.add(
        Icon(
          Icons.brightness_1_rounded,
          color: Colors.blueGrey.shade300,
          size: 10.0,
        ),
      );
    }
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  //ALL VARIABLES
  bool _isVibrationEnabled = true;
  bool _isClockStarted = false;
  bool _isPaused = false;
  bool _isBreakTime = false;
  bool _isEnableMelody = true;
  bool _isDarkModeEnabled = false;
  int focusTimeInMinutes = 25;
  int breakTimeInMinutes = 5;
  int varSeconds = 60;
  final pomodoroManager = PomodoroAlarmManager();
  final CountDownController _clockController = CountDownController();
  bool _isLoading = true; // Track loading state
  int _initialDuration = 0; // Store initial timer duration

  PermissionStatus _exactAlarmPermissionStatus = PermissionStatus.granted;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
    NotificationService().initNotification();
    _checkExactAlarmPermission();
  }

  Future<void> _initializeSharedPreferences() async {
    await getSharedSettingsPrerefence();

    // Calculate remaining time dynamically
    int calculatedDuration = await TimerSyncHandler().calculateRemainingTime(
        (_isBreakTime ? breakTimeInMinutes : focusTimeInMinutes) * varSeconds);

    // Determine if calculatedDuration is valid
    bool hasValidSavedTime = calculatedDuration > 0 &&
        calculatedDuration <=
            (_isBreakTime
                ? breakTimeInMinutes * varSeconds
                : focusTimeInMinutes * varSeconds);

    setState(() {
      _initialDuration = hasValidSavedTime
          ? calculatedDuration
          : focusTimeInMinutes * varSeconds; // Use default duration if invalid
      _isLoading = false;
    });
  }

  //MAIN SCREEN-UI
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height / 2.5;
    final double width = MediaQuery.of(context).size.width / 1.2;

    CircularCountDownTimer clock = buildCircularCountDownTimer(height, width);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text("Pomodoro",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              // Navigate to settings and wait for result
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );

              // Refresh shared preferences after returning
              await getSharedSettingsPrerefence();

              // If the clock is not running, restart it with the updated duration
              if (!_isClockStarted) {
                setState(() {
                  !_isBreakTime
                      ? _restartClock(duration: focusTimeInMinutes * varSeconds)
                      : _restartClock(
                      duration: breakTimeInMinutes * varSeconds);
                });
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              clock,
              Column(
                children: [
                  Text(
                    _isBreakTime ? "Break Time..." : "Focus Time...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.timesCompleted,
                  ),
                ],
              ),
              !_isBreakTime
              //BUTTONS FOR FOCUS TIME
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //PLAY BUTTON
                  if (!_isClockStarted || _isPaused)
                    ClockControlButton(
                        onTap: () async {
                          if (!_isClockStarted) {
                            startClock();
                          } else {
                            resumeClock();
                          }
                        },
                        color: Colors.blueAccent,
                        icon: Icons.play_arrow,
                        width: width),

                  //PAUSE BUTTON
                  if (_isClockStarted && !_isPaused)
                    ClockControlButton(
                        onTap: pauseClock,
                        color: Colors.orangeAccent,
                        icon: Icons.pause,
                        width: width),

                  //RESET BUTTON
                  if (_isPaused)
                    ClockControlButton(
                        onTap: () {
                          resetClock(isBreakTime: false);
                          pomodoroManager.cancelPomodoroAlarm();
                        },
                        color: Colors.redAccent,
                        icon: Icons.replay,
                        width: width)
                ],
              )
                  :
              //BUTTONS FOR BREAK TIME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //PLAY BUTTON
                  if (!_isClockStarted || _isPaused)
                    ClockControlButton(
                        onTap: () {
                          if (!_isClockStarted) {
                            startClock();
                          } else {
                            resumeClock();
                          }
                        },
                        color: Colors.blueAccent,
                        icon: Icons.play_arrow,
                        width: width),

                  //SKIP BUTTON
                  if (_isClockStarted && !_isPaused)
                    Column(
                      children: [
                        ClockControlButton(
                            onTap: () {
                              skipTheBreak();
                            },
                            color: Colors.orangeAccent,
                            icon: Icons.skip_next,
                            width: width),
                        const SizedBox(height: 5.0),
                        const Center(
                          child: BlinkText(
                            'Skip the break',
                            style: TextStyle(
                                fontSize: 20.0,
                                color: Colors.orangeAccent),
                            beginColor: Colors.orangeAccent,
                            endColor: Colors.transparent,
                            times: 10,
                            duration: Duration(milliseconds: 1000),
                          ),
                        )
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility to restart the clock
  void _restartClock({required int duration, bool autoPause = true}) {
    _clockController.restart(duration: duration);
    if (autoPause) _clockController.pause();
  }

  void skipTheBreak() {
    setState(() {
      _isBreakTime = false;
      _restartClock(duration: focusTimeInMinutes * varSeconds);
      _isClockStarted = false;
      _isPaused = false;
      pomodoroManager.cancelPomodoroAlarm();
    });
  }

  //Start the clock
  void startClock() {
    setState(() {
      _scheduleAlarmNotification();
      _clockController.start();
      startTimerInNotificationBar(_clockController);
      _isClockStarted = true;
      _isPaused = false;
    });
  }

  //Pause the clock
  void pauseClock() async {
    setState(() {
      _clockController.pause();
      _isPaused = true;
      pomodoroManager.cancelPomodoroAlarm();
    });
  }

  //Resume the clock
  void resumeClock() {
    setState(() {
      _scheduleAlarmNotification();
      _clockController.resume();
      startTimerInNotificationBar(_clockController);
      _isPaused = false;
      _isClockStarted = true;
    });
  }

  void resetClock({required bool isBreakTime}) async {
    setState(() {
      if (isBreakTime) {
        debugPrint("Break time");
        _restartClock(duration: breakTimeInMinutes * varSeconds);
        _isBreakTime = true;
      } else {
        debugPrint("Focus time");
        _restartClock(duration: focusTimeInMinutes * varSeconds);
        _isBreakTime = false;
      }
      _clockController.pause(); // Ensure the timer does not auto-start
      _isPaused = false;
      _isClockStarted = false;
    });
  }

  // Handle session completion
  Future<void> handleCompletion() async {
    _updateTimesCompleted();
    if (!_isBreakTime) {
      resetClock(isBreakTime: true);
    } else {
      resetClock(isBreakTime: false);
    }
    await _showCompletionDialog();
  }

  //CircularCountDownTimer build
  CircularCountDownTimer buildCircularCountDownTimer(
      double height, double width) {
    return CircularCountDownTimer(
      controller: _clockController,
      duration: _initialDuration,
      height: height,
      width: width,
      ringColor: Colors.grey.shade800,
      fillColor: Colors.blueAccent,
      backgroundColor: Colors.grey.shade900,
      strokeCap: StrokeCap.round,
      isReverse: true,
      isReverseAnimation: true,
      autoStart: false,
      textStyle: const TextStyle(
        fontSize: 55.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      onComplete: handleCompletion,
    );
  }

  void _scheduleAlarmNotification() {
    // Attempt to parse the time as an integer

    final time = _clockController.getTime();
    debugPrint('Time from clock controller: $time');

    final int remainingTimeInSeconds =
    parseTimeStringToSeconds(_clockController.getTime());

    final int defaultPomodoroDuration = focusTimeInMinutes * varSeconds;
    final int finalRemainingTimeInSeconds = (remainingTimeInSeconds > 0)
        ? remainingTimeInSeconds
        : defaultPomodoroDuration;

    debugPrint('Remaining time in seconds $finalRemainingTimeInSeconds');

    pomodoroManager.schedulePomodoroAlarm(
      durationInSeconds: finalRemainingTimeInSeconds,
      alarmTitle: 'Pomodoro Complete',
      alarmBody:
      !_isBreakTime ? 'Time to take a break!' : 'It is time to focus!',
    );
    debugPrint(
        "Alarm scheduled for ${DateTime.now().add(Duration(seconds: finalRemainingTimeInSeconds))}");
  }

  void startTimerInNotificationBar(CountDownController clockController) {
    pomodoroManager.startTimer(clockController);
  }

  // Update times completed
  void _updateTimesCompleted() {
    int indexTimesCompleted = widget.timesCompleted
        .indexWhere((icon) => icon.color == Colors.blueGrey.shade300);

    if (indexTimesCompleted != -1 && !_isBreakTime) {
      setState(() {
        widget.timesCompleted[indexTimesCompleted] = const Icon(
          Icons.brightness_1_rounded,
          color: Colors.greenAccent,
          size: 11.0,
        );
      });
    }
  }

// Show completion dialog
  Future<void> _showCompletionDialog() async {
    await NDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: const Text("Session Complete!"),
      content: Padding(
        padding: const EdgeInsets.only(left: 10, top: 20, bottom: 40),
        child: !_isBreakTime
            ? const Text("Great job! Let's focus again.")
            : const Text("Great job! Take a short break."),
      ),
      actions: [
        DialogActionButton(isBreakTime: _isBreakTime),
      ],
    ).show(context);
  }

  getSharedSettingsPrerefence() async {
    focusTimeInMinutes = await PreferencesService.getFocusTime();
    breakTimeInMinutes = await PreferencesService.getBreakTime();
    _isVibrationEnabled = await PreferencesService.isVibrationEnabled();
    _isEnableMelody = await PreferencesService.isMelodyEnabled();
    _isDarkModeEnabled = await PreferencesService.isDarkModeEnabled();
    setState(() {});
  }

  void _checkExactAlarmPermission() async {
    final currentStatus = await Permission.scheduleExactAlarm.status;
    setState(() {
      _exactAlarmPermissionStatus = currentStatus;
    });
  }
}
