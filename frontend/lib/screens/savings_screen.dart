import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/savings.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = [
    const SavingsListView(),
    const AddSavingView(),
    const AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Saving',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// --- Add Saving View ---

class AddSavingView extends StatefulWidget {
  const AddSavingView({super.key});

  @override
  State<AddSavingView> createState() => _AddSavingViewState();
}

class _AddSavingViewState extends State<AddSavingView> {
  final _amountController = TextEditingController();
  final _itemController = TextEditingController();
  final _actionController = TextEditingController(text: 'not buying');

  bool _loading = false;
  String? _error;
  String? _success;

  Currency _selectedCurrency = Currency.cad;
  DateTime _selectedDate = DateTime.now();

  bool _showDatePicker = false;
  bool _showCurrencyPicker = false;

  // tracks which month is displayed in the calendar
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    _calendarMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _itemController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    return '${_monthAbbr(_selectedDate.month)} ${_selectedDate.day}';
  }

  String _monthAbbr(int month) {
    const abbrs = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return abbrs[month - 1];
  }

  String _monthName(int month) {
    const names = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return names[month - 1];
  }

  Future<void> _submit() async {
    if (_amountController.text.isEmpty || _itemController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      setState(() => _error = 'Please enter a valid amount');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final api = ApiService();
    final description = '${_actionController.text} ${_itemController.text}';
    final saving = await api.addSaving(amount, description, _selectedCurrency);

    setState(() {
      _loading = false;
      if (saving != null) {
        _success = 'Saving logged!';
        _amountController.clear();
        _itemController.clear();
        _actionController.text = 'not buying';
        _selectedDate = DateTime.now();
        _selectedCurrency = Currency.cad;
        _showDatePicker = false;
        _showCurrencyPicker = false;
      } else {
        _error = 'Failed to log saving, please try again';
      }
    });
  }

  // builds the inline tappable chip for date and currency
  Widget _chip({
    required String label,
    required VoidCallback onTap,
    required bool isOpen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          Icon(
            isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () => setState(() {
                  _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S','M','T','W','T','F','S']
                .map((d) => SizedBox(
                      width: 32,
                      child: Text(d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = index - startWeekday + 1;
              final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _showDatePicker = false;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.black : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPicker() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: Currency.values.map((currency) {
          final isLast = currency == Currency.values.last;
          final isSelected = currency == _selectedCurrency;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCurrency = currency;
              _showCurrencyPicker = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currency.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check, size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            const Text(
              'Log a Saving',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // sentence
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                // only show "On" if not today
                if (!_isToday)
                  const Text('On', style: TextStyle(fontSize: 18)),

                _chip(
                  label: _dateLabel,
                  onTap: () => setState(() {
                    _showDatePicker = !_showDatePicker;
                    _showCurrencyPicker = false;
                  }),
                  isOpen: _showDatePicker,
                ),

                const Text('I saved around', style: TextStyle(fontSize: 18)),

                _inlineField(
                  controller: _amountController,
                  hint: '___',
                  keyboardType: TextInputType.number,
                  width: 72,
                ),

                _chip(
                  label: _selectedCurrency.name.toUpperCase(),
                  onTap: () => setState(() {
                    _showCurrencyPicker = !_showCurrencyPicker;
                    _showDatePicker = false;
                  }),
                  isOpen: _showCurrencyPicker,
                ),

                const Text('by', style: TextStyle(fontSize: 18)),

                _inlineField(
                  controller: _actionController,
                  hint: 'not buying',
                  width: 110,
                ),

                _inlineField(
                  controller: _itemController,
                  hint: '____',
                  width: 120,
                ),
              ],
            ),

            // date picker drops below sentence
            if (_showDatePicker) _buildCalendar(),

            // currency picker drops below sentence
            if (_showCurrencyPicker) _buildCurrencyPicker(),

            const SizedBox(height: 48),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _success!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineField({
    required TextEditingController controller,
    required String hint,
    required double width,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
            decoration: TextDecoration.underline,
          ),
          prefixText: prefix,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// --- Savings List View ---

class SavingsListView extends StatelessWidget {
  const SavingsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Savings List')),
    );
  }
}

// --- Account View ---

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Account')),
    );
  }
}