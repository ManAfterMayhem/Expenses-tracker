import 'package:expense_tracker_minimal/bar_style/multi_bar.dart';
import 'package:expense_tracker_minimal/components/custom_list.dart';
import 'package:expense_tracker_minimal/database/expense_database.dart';
import 'package:expense_tracker_minimal/helpers/helper_functions.dart';
import 'package:expense_tracker_minimal/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
  // void openEditBox(Expense expense) {
  //   String existingName = expense.name;
  //   String existingAmount = expense.amount.toString();
  // }
}

class _HomePageState extends State<HomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  Future<Map<int, double>>? _monthlyTotalFuture;
  @override
  void initState() {
    super.initState();

    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    refreshGraphData();
    super.initState();
  }

  void refreshGraphData() {
    _monthlyTotalFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotal();
  }

  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Expense',
              ),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                hintText: 'Amount',
              ),
            ),
          ],
        ),
        actions: [
          cancelButton(),
          saveButton(),
        ],
      ),
    );
  }

  void openEditBox(Expense expense) {
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: existingName,
              ),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                hintText: existingAmount,
              ),
            ),
          ],
        ),
        actions: [
          cancelButton(),
          editExpenseButton(expense),
        ],
      ),
    );
  }

  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        actions: [
          cancelButton(),
          deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(builder: (context, value, child) {
      int startMonth = value.getStartMonth();
      int startYear = value.getStartYear();
      int currentMonth = DateTime.now().month;
      int currentYear = DateTime.now().year;
      int monthCount =
          calculateMonthCount(startYear, startMonth, currentYear, currentMonth);
      return Scaffold(
          backgroundColor: Colors.grey[200],
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: FutureBuilder(
                      future: _monthlyTotalFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final monthlyTotals = snapshot.data ?? {};
                          List<double> monthlySummary = List.generate(
                              monthCount,
                              (index) =>
                                  monthlyTotals[startMonth + index] ?? 0.0);
                          return MyBarGraph(
                              monthlySummary: monthlySummary,
                              startMonth: startMonth);
                        } else {
                          return const Text('Loading...');
                        }
                      }),
                ),
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      Expense individualExpense = value.allExpenses[index];
                      return MyList(
                        title: individualExpense.name,
                        trailing: formatAmout(individualExpense.amount),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                      );
                    },
                    itemCount: value.allExpenses.length,
                  ),
                ),
              ],
            ),
          ));
    });
  }

  Widget cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        nameController.clear();
        refreshGraphData();
      },
      child: const Text('Cancel'),
    );
  }

  saveButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          Navigator.pop(context, null);
          Expense newExpense = Expense(
              name: nameController.text,
              amount: convertStringToDouble(amountController.text),
              date: DateTime.now());
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);
          refreshGraphData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  double convertStringToDouble(String string) {
    double? amount = double.tryParse(string);
    return amount ?? 0.0;
  }

  editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          Navigator.pop(context, null);
          Expense updatedExpense = Expense(
              name: nameController.text.isNotEmpty
                  ? nameController.text
                  : expense.name,
              amount: amountController.text.isNotEmpty
                  ? convertStringToDouble(amountController.text)
                  : expense.amount,
              date: DateTime.now());
          int existingId = expense.id;
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);
          refreshGraphData();
        }
      },
      child: const Text('Save'),
    );
  }

  Widget deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<ExpenseDatabase>().deleteExpense(id);
        refreshGraphData();
      },
      child: const Text('Delete'),
    );
  }
}
