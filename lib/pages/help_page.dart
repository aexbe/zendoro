import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Tutorial'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTutorialSection(
              context,
              title: 'Getting Started',
              steps: [
                '1. Create your first routine in the Task Planner',
                '2. Start a focus session in Pomodoro / Focus',
                '3. Track your progress in Daily Log',
              ],
            ),
            _buildTutorialSection(
              context,
              title: 'Daily Log',
              steps: [
                '• The Daily Log is your personal productivity dashboard.',
                '• Click on the "+" button or the specific date to add a new log entry.',
                '• Log about the day and activities throughout the day.',
                '• You can add multiple entries for different times of the day.',
                '• Set your mood and energy level for the day.',
                '• Add a note for what you are grateful for today.',
                '• Add a note for what you could improve today.',
                '• Add a note for what you have achieved today.',
                '• You can edit the specific day entry by clicking on the edit icon in the top right corner of the entry.',
                '• Always remember to save your changes after editing.',
              ],
            ),
            _buildTutorialSection(
              context,
              title: 'Pomodoro / Focus Page',
              steps: [
                '• The Pomodoro Page is divided into 4 sessions.',
                '• Note that once the Pomodoro session is started, the timer will run in the background even if you switch to another page. But ensure that the app is not killed. Ensure that the app is running in the background. Ensure that you have enabled the "No Restrictions" permission in the app settings by going in App info > Battery > No restriction (selected).',
                '• Note that the Pomodoro session time elapsed MAY be reserved if the app is killed.',
                '• Note that even if you allowed all permission to the app, the app may be killed if you have switched on Battery Saver mode.',
                '• Each session can be customized in duration and goals.',
                '• To modify the duration of a session (pomodoro, focus), click on settings icon and then write the desired duration in minutes.',
                '• To modify the daily focus goal, click on settings icon and then write the desired daily focus goal in hours.',
                '• Pomodoro:',
                '   - A time management technique that breaks work into intervals, traditionally 25 minutes in length, separated by short breaks. Pomodoro session has a default duration of 25 minutes.',
                '   - Click the start button to begin.',
                '   - Click the stop & save button to end save the session.',
                '   - Click the pause button to pause the session.',
                '   - Click the resume button to resume the session after pausing.',
                '   - Click the reset button to reset the session. [Caution: the elapsed time will not be saved]',
                '• Short Break:',
                '   - A short break is a brief pause taken after a Pomodoro session to rest and recharge. Short break has a default duration of 5 minutes.',
                '   - Click the start button to begin the short break.',
                '   - Click the stop button to pause or end the short break.',
                '   - Click the pause button to pause the short break.',
                '   - Click the resume button to resume the short break after pausing.',
                '   - Click the reset button to reset the short break.',
                '• Focus Session:',
                '   - A focus session is a longer uninterrupted work period, ideal for deep work. Focus session starts from 0 to infinity minutes, use it wisely.',
                '   - Click the start button to begin the focus session.',
                '   - Click the stop button to pause or end the focus session.',
                '   - Click the pause button to pause the focus session.',
                '   - Click the resume button to resume the focus session after pausing.',
                '   - Click the reset button to reset the focus session.',
                '• Scrolling down, you will see a text button as "Get a detailed report ->". Click that to see a detailed long daily and weekly analysis',
              ],
            ),
            _buildTutorialSection(
              context,
              title: 'Managing Tasks',
              steps: [
                '• The Task Planner allows you to create and manage your daily tasks.',
                '• Add tasks by clicking the "+" button.',
                '• Set the title and description for each task.',
                '• Set durations for each task to estimate how long they will take.',
                '• Mark tasks as completed by tapping the checkbox next to them.',
                '• Delete tasks by swiping left or right on them.',
                '• Once created the task will be shown in the Pomodoro / Focus page and in the home page.',
              ],
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Need more help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.contact_support),
              title: Text('Contact Support'),
              subtitle: Text('Email us at zendoro.help@gmail.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialSection(BuildContext context, {required String title, required List<String> steps}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                step,
                style: const TextStyle(fontSize: 16),
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}