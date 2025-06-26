import 'package:flutter/material.dart';
import 'package:xmasfriend/core/Features/home/widgets/common_text_widget.dart';
import 'package:xmasfriend/core/Features/home/widgets/participant_card_widget.dart';
import 'package:xmasfriend/core/employee_pair.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List of all employees entered by HR
  List<String> initialList = [];
  // The shuffled list of employees used for generating pairings
  List<String> randomizedList = [];
  // The complete list of generated cyclic pairings
  List<EmployeePair> allPairings = []; // Renamed from selectedList for clarity

  // List of suggested gifts, will be shuffled for random presentation
  List<String> suggestGiftList = [
    "Watches",
    "Shoe",
    "Perfume",
    "Necklace",
    "Flower vase",
    "Jacket",
    "Amazon Gift card",
    "Lamp",
    "Lighter",
    "Phone",
    "Concert Tickets",
    "Smart Speaker",
    "Headphones",
    "Coffee Maker",
    "Book Set",
    "Board Game",
    "Gourmet Food Basket",
    "Spa Voucher",
    "Plant",
    "Personalized Mug",
  ];
  // Shuffled list of gifts
  List<String> randomizedGiftList = [];
  // Index to pick gifts from randomizedGiftList to ensure unique sets of 3
  int _currentGiftSuggestionIndex = 0;

  String? errorMessage; // To display errors like not enough employees

  // Controller for the employee input text field in the bottom sheet
  final TextEditingController _employeeInputController =
      TextEditingController();

  // State variables for the interactive flow
  String? _selectedPickerName; // The employee whose turn it is to pick
  String?
  _revealedPickedName; // The employee who was picked by _selectedPickerName
  List<String> _currentGiftSuggestions =
      []; // 3 gifts shown for the current pick
  bool _showPickFriendButton =
      false; // Controls visibility of "Pick your friend" button
  bool _showExploreGiftButton =
      false; // Controls visibility of "Explore suggested gift" button
  bool _showGiftChoices = false; // Controls visibility of the 3 gift choices

  // Set to keep track of employees who have already picked their friend in the current session
  Set<String> _completedPickers = {};

  @override
  void initState() {
    super.initState();
    // Initialize randomized gift list
    randomizedGiftList = List.from(suggestGiftList);
    randomizedGiftList.shuffle();
    _currentGiftSuggestionIndex = 0; // Reset index for gifts
  }

  @override
  void dispose() {
    _employeeInputController.dispose();
    super.dispose();
  }

  /// Generates the cyclic pairings based on `initialList` and resets the interactive flow.
  void _generateAndDisplayPairings() {
    setState(() {
      _getRandomizedList(); // Shuffle current employees
      _matchPairs(randomizedList); // Generate all pairings for this shuffle
      _resetInteractiveFlow(); // Reset UX states
      _completedPickers.clear(); // Clear who has picked
      errorMessage = null; // Clear any previous error
    });
  }

  /// Resets the interactive UI elements for a new pick.
  void _resetInteractiveFlow() {
    setState(() {
      _selectedPickerName = null;
      _revealedPickedName = null;
      _currentGiftSuggestions = [];
      _showPickFriendButton = false;
      _showExploreGiftButton = false;
      _showGiftChoices = false;
    });
  }

  /// Shuffles the initial list of employees and updates `randomizedList`.
  /// Uses a copy to avoid modifying the original `initialList`.
  void _getRandomizedList() {
    randomizedList = List.from(initialList);
    randomizedList.shuffle(); // In-place shuffle
  }

  /// Generates cyclic pairings from the `randomizedList`.
  /// Stores results in `allPairings` and handles error conditions.
  void _matchPairs(List<String> employees) {
    allPairings.clear(); // Clear previous pairings

    if (employees.length < 3) {
      errorMessage =
          'A minimum of 3 unique employees are required for cyclic pairings.';
      return;
    }

    // Generate the cyclic pairings
    for (int i = 0; i < employees.length; i++) {
      final String picker = employees[i];
      // The person picked is the next person in the array.
      // For the last person, they pick the first person to complete the cycle.
      final String picked = employees[(i + 1) % employees.length];
      allPairings.add(EmployeePair(picker: picker, picked: picked));
    }
  }

  /// Finds and reveals the picked friend for the currently selected picker.
  void _revealPickedFriend() {
    setState(() {
      if (_selectedPickerName != null) {
        final pair = allPairings.firstWhere(
          (p) => p.picker == _selectedPickerName,
          orElse:
              () => EmployeePair(
                picker: "",
                picked: "Error: Not found",
              ), // Fallback
        );
        _revealedPickedName = pair.picked;
        _showPickFriendButton = false;
        _showExploreGiftButton = true;
        _completedPickers.add(_selectedPickerName!); // Mark as completed
      }
    });
  }

  /// Generates and displays 3 unique gift suggestions.
  void _exploreSuggestedGift() {
    setState(() {
      _currentGiftSuggestions.clear();
      _showGiftChoices = true;
      _showExploreGiftButton = false; // Hide after showing gifts

      // Ensure we have enough gifts left. If not, reshuffle the main gift list
      // and reset the index. This provides unique sets of 3 until all are used.
      if (_currentGiftSuggestionIndex + 3 > randomizedGiftList.length) {
        randomizedGiftList.shuffle();
        _currentGiftSuggestionIndex = 0;
      }

      // Pick 3 unique gifts from the randomized list
      for (int i = 0; i < 3; i++) {
        _currentGiftSuggestions.add(
          randomizedGiftList[_currentGiftSuggestionIndex %
              randomizedGiftList.length],
        );
        _currentGiftSuggestionIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Pairings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reset the text controller before showing the bottom sheet
          _employeeInputController.clear();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows keyboard to push sheet up
            builder:
                (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Make column only take needed space
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18.0),
                      CommonTextWidget(
                        title:
                        'Add Employee',
                        color: Colors.deepPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8.0),
                      CommonTextWidget(
                        title:
                        'Enter employee names to add them to the list of participants.',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _employeeInputController,
                        decoration: InputDecoration(
                          hintText: 'Enter employee name',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black38),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.indigo),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Field cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_employeeInputController.text.trim().isNotEmpty) {
                            setState(() {
                              // Add employee to the list, trimmed to remove extra spaces
                              initialList.add(
                                _employeeInputController.text.trim(),
                              );
                              _employeeInputController
                                  .clear(); // Clear for next entry
                            });
                            // Optionally, pop the bottom sheet after adding
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                            double.infinity,
                            50,
                          ), // Full width button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: CommonTextWidget(
                          title:
                          'Add Employee',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10), // Padding below button
                    ],
                  ),
                ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section for current employees (Dynamically added)
              ParticipantCardWidget(
                initialList: initialList,
                completedPickers: _completedPickers,
              ),

              // Button to trigger pairing generation and reset flow (if list isn't empty)
              ElevatedButton(
                onPressed:
                    initialList.isEmpty
                        ? null
                        : _generateAndDisplayPairings, // Disable if no employees
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: CommonTextWidget(
                  title:
                  'Generate/Reset All Pairings',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Display error message if any (e.g., less than 3 participants)
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Drag Target Area (Drop Zone)
              if (initialList.isNotEmpty &&
                  allPairings.isNotEmpty) // Only show if pairings are generated
                DragTarget<String>(
                  onAccept: (data) {
                    // Only accept if this picker hasn't completed their turn yet
                    if (!_completedPickers.contains(data)) {
                      setState(() {
                        _selectedPickerName = data;
                        _revealedPickedName = null; // Clear previous reveal
                        _currentGiftSuggestions = []; // Clear previous gifts
                        _showPickFriendButton = true;
                        _showExploreGiftButton = false;
                        _showGiftChoices = false;
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            candidateData.isNotEmpty
                                ? Colors.deepPurple.shade50
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              candidateData.isNotEmpty
                                  ? Colors.deepPurple.shade300
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.drag_handle,
                            size: 40,
                            color: Colors.deepPurple.shade300,
                          ),
                          const SizedBox(height: 6),
                          CommonTextWidget(
                            title:
                            'Drag an employee chip here to start their pick!',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),

                          // Display the selected picker
                          if (_selectedPickerName != null)
                            Column(
                              children: [
                                CommonTextWidget(
                                  title:
                                  'Selected Picker::',
                                  fontSize: 18,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(_selectedPickerName!),
                                  backgroundColor: Colors.deepPurple.shade200,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                ),
                                const SizedBox(height: 0),
                              ],
                            ),

                          // "Pick your friend" button
                          if (_showPickFriendButton)
                            ElevatedButton.icon(
                              onPressed: _revealPickedFriend,
                              icon: const Icon(Icons.person_search),
                              label: const Text('Pick Your Friend'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          const SizedBox(height: 9),

                          // Display the revealed picked friend
                          if (_revealedPickedName != null)
                            Column(
                              children: [
                                CommonTextWidget(
                                  title:
                                  'You picked:',
                                  fontSize: 18,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(_revealedPickedName!),
                                  backgroundColor: Colors.deepOrange.shade200,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),

                          // "Explore suggested gift" button
                          if (_showExploreGiftButton)
                            ElevatedButton.icon(
                              onPressed: _exploreSuggestedGift,
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Explore Suggested Gifts'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Display gift choices
                          if (_showGiftChoices &&
                              _currentGiftSuggestions.isNotEmpty)
                            Column(
                              children: [
                                CommonTextWidget(
                                  title:
                                  'Suggested Gifts:',
                                  fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  alignment: WrapAlignment.center,
                                  children:
                                      _currentGiftSuggestions
                                          .map(
                                            (gift) => ActionChip(
                                              label: Text(gift),
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              labelStyle: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              onPressed: () {
                                                // Optionally, handle selection here (e.g., store the chosen gift)
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'You selected: $gift',
                                                    ),
                                                  ),
                                                );
                                                // After selection, you might want to reset for the next picker
                                                _resetInteractiveFlow();
                                              },
                                            ),
                                          )
                                          .toList(),
                                ),
                                const SizedBox(height: 8),
                                // Button to allow picking another person or reset
                                ElevatedButton.icon(
                                  onPressed: _resetInteractiveFlow,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Pick Another Person'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),

              if (initialList.isNotEmpty &&
                  allPairings.isEmpty &&
                  errorMessage == null)
                Center(
                  child: CommonTextWidget(
                    title:
                        'Employees added! Now press "Generate/Reset All Pairings" to prepare the picks.',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              // Initial prompt if no pairings generated yet
              if (initialList.isEmpty)
                Center(
                  child: CommonTextWidget(
                    title:
                        'Tap the + button to add employees and start generating pairings!',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
