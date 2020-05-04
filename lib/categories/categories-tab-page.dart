import 'package:flutter/material.dart';
import 'package:piggybank/categories/categories-list.dart';
import 'package:piggybank/categories/edit-category-page.dart';
import './i18n/categories-page.i18n.dart';

import '../movements/movements-group-card.dart';

class CategoryTabPage extends StatefulWidget {
  @override
  CategoryTabPageState createState() => CategoryTabPageState();
}

class CategoryTabPageState extends State<CategoryTabPage> {

  int indexTab;

  final GlobalKey<CategoriesListState> _expensesCategoryKey = GlobalKey();
  final GlobalKey<CategoriesListState> _incomingCategoryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    indexTab = 0;
  }

  void refreshExpenseCategoriesList() async {
    await _expensesCategoryKey.currentState.fetchCategories();
  }

  void refreshIncomeCategoriesList() async {
    await _incomingCategoryKey.currentState.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            onTap: (index){
              setState(() {
                indexTab = index;
              });
            },
            tabs: [
              Tab(text: "Expenses",),
              Tab(text: "Income",),
              Tab(text: "Tags",),
            ],
          ),
          title: Text('Categories'),
        ),
        body: TabBarView(
          children: [
            CategoriesList(key: _expensesCategoryKey,categoryType: 0),
            CategoriesList(key: _incomingCategoryKey, categoryType: 1),
            Icon(Icons.directions_bike),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: ()  async {
            if (indexTab == 0) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditCategoryPage(categoryType: 0)),
              );
              await refreshExpenseCategoriesList();
            }

            if (indexTab == 1) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditCategoryPage(categoryType: 1)),
              );
              await refreshIncomeCategoriesList();
            }
          },
          tooltip: 'Increment Counter',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

}