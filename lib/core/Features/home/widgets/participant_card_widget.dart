import 'package:flutter/material.dart';

class ParticipantCardWidget extends StatelessWidget {
  const ParticipantCardWidget({
    super.key,
    required this.initialList,
    required Set<String> completedPickers,
  }) : _completedPickers = completedPickers;

  final List<String> initialList;
  final Set<String> _completedPickers;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participants:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            if (initialList.isEmpty)
              const Text(
                'No employees added yet. Tap + to add participants.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: initialList
                    .map((name) => Draggable<String>(
                  data: name, // Data to be passed on drag
                  feedback: Material(
                    color: Colors.transparent, // Make Material transparent
                    elevation: 6, // Give it some elevation for visual pop
                    child: Chip(
                      label: Text(name),
                      backgroundColor: Colors.deepPurple.withOpacity(0.7),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                  childWhenDragging: Chip(
                    label: Text(name),
                    backgroundColor: Colors.grey.shade300,
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                  child: Chip(
                    label: Text(name),
                    backgroundColor: _completedPickers.contains(name)
                        ? Colors.green.shade100 // Indicate if picked
                        : Colors.deepPurple.shade100,
                    labelStyle: _completedPickers.contains(name)
                        ? const TextStyle(color: Colors.green)
                        : const TextStyle(color: Colors.deepPurple),
                  ),
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}