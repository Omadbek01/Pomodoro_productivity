import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:ndialog/ndialog.dart';
import 'package:vibration/vibration.dart';

class HomePage extends StatefulWidget {
  final List<Icon> timesCompleted = [];

  HomePage() {
    for (var i = 0; i < 3; i++) {
      timesCompleted.add(
        Icon(
          Icons.brightness_1_rounded,
          color: Colors.blueGrey.shade300,
          size: 9.0,
        ),
      );
    }
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CountDownController _clockController = CountDownController();
  bool _isClockStarted = false;
  bool _isPaused = false;
  bool _isBreakTime = false;
  int focusTimeInMinutes = 1;
  int breakTimeInMinutes = 1;

  void startClock() {
    setState(() {
      _clockController.start();
      _isClockStarted = true;
      _isPaused = false;
    });
  }

  void pauseClock() {
    setState(() {
      _clockController.pause();
      _isPaused = true;
    });
  }

  void resumeClock() {
    setState(() {
      _clockController.resume();
      _isPaused = false;
    });
  }

  void resetClock() {
    setState(() {
      _clockController.restart(
          duration: focusTimeInMinutes * 5); // Reset to 25 minutes
      _clockController.pause(); // Ensure the timer does not auto-start
      _isPaused = false;
      _isClockStarted = false;
      _isBreakTime = false;
    });
  }

  void resetClockForPause() {
    setState(() {
      debugPrint("Pause Pause Pause");
      _clockController.restart(
          duration: breakTimeInMinutes * 3); // Reset to 5 minutes
      _clockController.pause(); // Ensure the timer does not auto-start
      _isPaused = false;
      _isClockStarted = false;
      _isBreakTime = true;
    });
  }

  Future<void> handleCompletion() async {
    int indexTimesCompleted = widget.timesCompleted
        .indexWhere((icon) => icon.color == Colors.blueGrey.shade300);

    if (_isBreakTime == false) {
      resetClockForPause();
    } else {
      resetClock();
    }

    if (indexTimesCompleted != -1 && _isBreakTime == true) {
      setState(() {
        widget.timesCompleted[indexTimesCompleted] = const Icon(
          Icons.brightness_1_rounded,
          color: Colors.greenAccent,
          size: 10.0,
        );
      });
    }

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
        AnimatedContainer(
          duration:
              const Duration(milliseconds: 300), // Duration for the animation
          curve: Curves.easeInOut, // Smooth curve for the animation
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
            child: TweenAnimationBuilder(
              duration: const Duration(
                  milliseconds: 300), // Duration for the text size animation
              tween:
                  Tween<double>(begin: 14.0, end: 24.0), // Animating font size
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
        ),
      ],
    ).show(context);

    if ((await Vibration.hasVibrator()) == true) {
      Vibration.vibrate(duration: 500);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height / 2.5;
    final double width = MediaQuery.of(context).size.width / 1.2;

    CircularCountDownTimer clock = CircularCountDownTimer(
      controller: _clockController,
      duration: focusTimeInMinutes * 5, // 25 minutes
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
            onPressed: () {
              // Navigate to settings page
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isClockStarted || _isPaused)
                    GestureDetector(
                      onTap: () {
                        if (!_isClockStarted) {
                          startClock();
                        } else {
                          resumeClock();
                        }
                      },
                      child: Container(
                        width: width / 2.5,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_arrow,
                              color: Colors.white, size: 40.0),
                        ),
                      ),
                    ),
                  if (_isClockStarted && !_isPaused)
                    GestureDetector(
                      onTap: pauseClock,
                      child: Container(
                        width: width / 2.5,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.pause,
                              color: Colors.white, size: 40.0),
                        ),
                      ),
                    ),
                  if (_isPaused)
                    GestureDetector(
                      onTap: resetClock,
                      child: Container(
                        width: width / 2.5,
                        height: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.replay,
                              color: Colors.white, size: 40.0),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
