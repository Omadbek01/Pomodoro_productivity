import 'package:flutter/material.dart';
import '../utils/settingsSharedPreferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _focusTime; // Default focus time in minutes
  int? _breakTime; // Default break time in minutes
  bool? _isVibrationEnabled;
  bool? _isMelodyEnabled;
  bool? _isDarkModeEnabled;
  String? _selectedMusic;
  // Dummy background music list
  final List<String> _backgroundMusicList = [
    "Silent Focus",
    "Forest Breeze",
    "Ocean Waves",
    "Rain Drops",
    "Meditation Melody",
    "Fireplace Crackle",
    "Chill Vibes",
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _selectedMusic = _backgroundMusicList.first;
  }

  // Load preferences from PreferencesService asynchronously
  Future<void> _loadPreferences() async {
    _focusTime = await PreferencesService.getFocusTime() ?? 25;
    _breakTime = await PreferencesService.getBreakTime() ?? 5;
    _isVibrationEnabled = await PreferencesService.isVibrationEnabled() ?? true;
    _isMelodyEnabled = await PreferencesService.isMelodyEnabled() ?? true;
    _isDarkModeEnabled = await PreferencesService.isDarkModeEnabled() ?? false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.black,
      ),
      body: _isVibrationEnabled == null
          ? const Center(
              child: CircularProgressIndicator(), // Show loader while loading
            )
          : Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  // Focus Time Setting
                  _buildTimeSetting(
                    title: "Focus Time (minutes)",
                    value: _focusTime ?? 25,
                    onChanged: (value) {
                      setState(() {
                        _focusTime = value;
                        PreferencesService.setFocusTime(value ?? 25);
                      });
                    },
                  ),

                  // Break Time Setting
                  _buildTimeSetting(
                    title: "Break Time (minutes)",
                    value: _breakTime ?? 5,
                    onChanged: (value) {
                      setState(() {
                        _breakTime = value;
                        PreferencesService.setBreakTime(value ?? 5);
                      });
                    },
                  ),

                  // Background Music Selection
                  ListTile(
                    title: const Text(
                      "Background Music (soon)",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedMusic,
                      dropdownColor: Colors.black,
                      items: _backgroundMusicList.map((String music) {
                        return DropdownMenuItem<String>(
                          value: music,
                          child: Text(
                            music,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        setState(() {
                          _selectedMusic = selected;
                          // Save the selected music to shared preferences or state
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Vibration Switch
                  _buildSwitch(
                    title: "Enable Vibration",
                    value: _isVibrationEnabled!,
                    onChanged: (value) {
                      setState(() {
                        _isVibrationEnabled = value;
                        PreferencesService.setVibrationEnabled(value);
                      });
                    },
                  ),

                  // Dark Mode Switch
                  _buildSwitch(
                    title: "Enable Light Mode (coming soon)",
                    value: _isDarkModeEnabled?? false,
                    onChanged: (value) {
                      setState(() {
                        _isDarkModeEnabled = value;
                        PreferencesService.setDarkModeEnabled(value);
                      });
                    },
                  ),

                  const SizedBox(height: 40),

                  // Save & Back button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, 60), // Full width, fixed height
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                      ),
                    ),
                    onPressed: () async {
                      print("Preferences saved: Focus Time = $_focusTime, Break Time = $_breakTime");
                      Navigator.pop(context); // Go back to the previous page
                    },
                    child: const Text('Save & Back',
                        style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeSetting({
    required String title,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: DropdownButton<int>(
        value: value,
        dropdownColor: Colors.grey.shade900,
        style: const TextStyle(color: Colors.white),
        items: List.generate(
          60,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text("${index + 1}"),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      activeColor: Colors.blueAccent,
      inactiveTrackColor: Colors.grey.shade800,
      onChanged: onChanged,
    );
  }
}