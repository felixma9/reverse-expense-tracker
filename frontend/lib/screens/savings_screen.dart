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

class SavingsListView extends StatefulWidget {
  const SavingsListView({super.key});

  @override
  State<SavingsListView> createState() => _SavingsListViewState();
}

class _SavingsListViewState extends State<SavingsListView> {
  final _api = ApiService();
  List<Saving> _savings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSavings();
  }

  Future<void> _fetchSavings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final savings = await _api.getSavings();
      savings.sort((a, b) => b.date.compareTo(a.date));
      setState(() { _savings = savings; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load savings'; _loading = false; });
    }
  }

  double get _currentMonthTotal {
    final now = DateTime.now();
    return _savings
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  Map<String, List<Saving>> get _groupedSavings {
    final Map<String, List<Saving>> grouped = {};
    for (final saving in _savings) {
      final key = '${saving.date.year}-${saving.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(saving);
    }
    return grouped;
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    const names = ['January','February','March','April','May','June',
                   'July','August','September','October','November','December'];
    return '${names[month - 1]} $year';
  }

  String _dayLabel(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatAmount(Saving saving) {
    return '\$${saving.amount.toStringAsFixed(2)} ${saving.currency.name.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Text(
              'Your savings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),

          // current month total card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved so far this month',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_currentMonthTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          // list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            TextButton(onPressed: _fetchSavings, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _savings.isEmpty
                        ? const Center(
                            child: Text(
                              'No savings yet.\nTap + to log your first one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSavings,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              children: _groupedSavings.entries.map((entry) {
                                final monthSavings = entry.value;
                                final monthTotal = monthSavings.fold(0.0, (sum, s) => sum + s.amount);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // month header
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _monthLabel(entry.key),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '\$${monthTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // entries card
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: monthSavings.asMap().entries.map((e) {
                                            final index = e.key;
                                            final saving = e.value;
                                            final isLast = index == monthSavings.length - 1;

                                            return GestureDetector(
                                              onTap: () => _openDetail(saving),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: isLast
                                                      ? null
                                                      : Border(
                                                          bottom: BorderSide(
                                                            color: Colors.grey.shade200,
                                                          ),
                                                        ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            _formatAmount(saving),
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                          if (saving.description != null) ...[
                                                            const SizedBox(height: 3),
                                                            Text(
                                                              saving.description!,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade600,
                                                              ),
                                                            ),
                                                          ],
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            _dayLabel(saving.date),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade400,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.chevron_right,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _openDetail(Saving saving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavingDetailSheet(
        saving: saving,
        onDeleted: _fetchSavings,
        onUpdated: _fetchSavings,
      ),
    );
  }
}

// --- Detail / Edit Bottom Sheet ---

class SavingDetailSheet extends StatefulWidget {
  final Saving saving;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  const SavingDetailSheet({
    super.key,
    required this.saving,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  State<SavingDetailSheet> createState() => _SavingDetailSheetState();
}

class _SavingDetailSheetState extends State<SavingDetailSheet> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  bool _loading = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.saving.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.saving.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _loading = true);
    final api = ApiService();
    final updated = await api.updateSaving(
      widget.saving.id,
      amount: amount,
      description: _descriptionController.text,
    );
    setState(() => _loading = false);

    if (updated != null && mounted) {
      widget.onUpdated();
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    setState(() => _loading = true);
    final api = ApiService();
    final success = await api.deleteSaving(widget.saving.id);
    setState(() => _loading = false);

    if (success && mounted) {
      widget.onDeleted();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saving detail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                child: Text(_editing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_editing) ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Save changes'),
            ),
          ] else ...[
            _detailRow('Amount', '\$${widget.saving.amount.toStringAsFixed(2)} ${widget.saving.currency.name.toUpperCase()}'),
            _detailRow('Description', widget.saving.description ?? '—'),
            _detailRow('Date', '${widget.saving.date.day}/${widget.saving.date.month}/${widget.saving.date.year}'),
          ],

          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : _delete,
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
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