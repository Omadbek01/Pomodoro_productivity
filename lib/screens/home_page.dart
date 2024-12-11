import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:ndialog/ndialog.dart';
import 'package:vibration/vibration.dart';
import '../utils/clockControlButton.dart';
import '../screens/settingsPage.dart';
import '../utils/settingsSharedPreferences.dart';

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
  final CountDownController _clockController = CountDownController();
  bool _isVibrationEnabled = true;
  bool _isClockStarted = false;
  bool _isPaused = false;
  bool _isBreakTime = false;
  bool _isMelodyEnabled = true;
  bool _isDarkModeEnabled = false;
  int focusTimeInMinutes = 1;
  int breakTimeInMinutes = 1;
  int varSeconds = 5;

  @override
  void initState() {
    _restartClock(duration: focusTimeInMinutes * varSeconds);
    getSharedSettingsPrerefence();
    super.initState();
  }

  //MAIN SCREEN-UI
  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height / 2.5;
    final double width = MediaQuery.of(context).size.width / 1.2;

    CircularCountDownTimer clock = buildCircularCountDownTimer(height, width);

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
                  !_isBreakTime?
                  _restartClock(duration: focusTimeInMinutes * varSeconds):
                  _restartClock(duration: breakTimeInMinutes * varSeconds);
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

              //BUTTONS
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
                        onTap: resetClock,
                        color: Colors.redAccent,
                        icon: Icons.replay,
                        width: width)
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

  //Start the clock
  void startClock() {
    setState(() {
      _clockController.start();
      _isClockStarted = true;
      _isPaused = false;
    });
  }

  //Pause the clock
  void pauseClock() {
    setState(() {
      _clockController.pause();
      _isPaused = true;
    });
  }

  //Resume the clock
  void resumeClock() {
    setState(() {
      _clockController.resume();
      _isPaused = false;
    });
  }

  //Reset the clock
  void resetClock() {
    setState(() {
      debugPrint("Focus time");
      _restartClock(duration: focusTimeInMinutes * varSeconds);
      _clockController.pause(); // Ensure the timer does not auto-start
      _isPaused = false;
      _isClockStarted = false;
      _isBreakTime = false;
    });
  }

  //Reset the clock for pause
  void resetClockForPause() {
    setState(() {
      debugPrint("Break time");
      _restartClock(duration: breakTimeInMinutes * (varSeconds - 2));
      _clockController.pause(); // Ensure the timer does not auto-start
      _isPaused = false;
      _isClockStarted = false;
      _isBreakTime = true;
    });
  }

  // Handle session completion
  Future<void> handleCompletion() async {
    await _handleVibration();
    _updateTimesCompleted();

    // Reset clock based on session type
    if (!_isBreakTime) {
      resetClockForPause();
    } else {
      resetClock();
    }

    // Show dialog
    await _showCompletionDialog();
  }

  //CircularCountDownTimer build
  CircularCountDownTimer buildCircularCountDownTimer(
      double height, double width) {
    return CircularCountDownTimer(
      controller: _clockController,
      duration: focusTimeInMinutes * varSeconds, // 25 minutes
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
        fontSize: 35.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      onComplete: handleCompletion,
    );
  }

  // Handle device vibration
  Future<void> _handleVibration() async {
    if ((await Vibration.hasVibrator()) == true && _isVibrationEnabled) {
      Vibration.vibrate(duration: 500);
      debugPrint("Vibrating for half a second.");
    } else {
      debugPrint("No vibration detected. Vibration pref: $_isVibrationEnabled");
    }
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
        _buildDialogActionButton(context),
      ],
    ).show(context);
  }

// Build dialog action button
  Widget _buildDialogActionButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(begin: 14.0, end: 24.0),
          builder: (context, fontSize, child) {
            return Text(
              !_isBreakTime ? "Start Focus" : "Start Break",
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  getSharedSettingsPrerefence() async {
    focusTimeInMinutes = await PreferencesService.getFocusTime();
    breakTimeInMinutes = await PreferencesService.getBreakTime();
    _isVibrationEnabled = await PreferencesService.isVibrationEnabled();
    _isMelodyEnabled = await PreferencesService.isMelodyEnabled();
    _isDarkModeEnabled = await PreferencesService.isDarkModeEnabled();
    setState(() {});
  }
}
