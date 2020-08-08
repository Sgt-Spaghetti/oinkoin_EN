
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:piggybank/categories/categories-tab-page-view.dart';
import 'package:piggybank/helpers/alert-dialog-builder.dart';
import 'package:piggybank/helpers/datetime-utility-functions.dart';
import 'package:piggybank/models/category-type.dart';
import 'package:piggybank/models/category.dart';
import 'package:piggybank/models/record.dart';
import 'package:piggybank/services/database/database-interface.dart';
import 'package:piggybank/services/service-config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../style.dart';
import './i18n/edit-record-page.i18n.dart';

class EditRecordPage extends StatefulWidget {

  /// EditMovementPage is a page containing forms for the editing of a Movement object.
  /// EditMovementPage can take the movement object to edit as a constructor parameters
  /// or can create a new Movement otherwise.

  Record passedRecord;
  Category passedCategory;
  EditRecordPage({Key key, this.passedRecord, this.passedCategory}) : super(key: key);

  @override
  EditRecordPageState createState() => EditRecordPageState(this.passedRecord, this.passedCategory);
}

class EditRecordPageState extends State<EditRecordPage> {

  DatabaseInterface database = ServiceConfig.database;
  final _formKey = GlobalKey<FormState>();
  Record record;

  Record passedRecord;
  Category passedCategory;
  String currency;

  EditRecordPageState(this.passedRecord, this.passedCategory);

  Future<String> getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? "€";
  }

  @override
  void initState() {
    super.initState();
    currency = "€";
    if (passedRecord != null) {
      record = passedRecord;
    } else {
      record = new Record(null, null, passedCategory, DateTime.now());
    }
    getCurrency().then((value) {
      setState(() {
        currency = value;
      });
    });
  }

  Widget _createCategoryCirclePreview() {
    Category defaultCategory = Category("Missing".i18n, color: Category.colors[0], iconCodePoint: FontAwesomeIcons.question.codePoint);
    Category toRender = (record.category == null) ? defaultCategory : record.category;
    return Container(
        margin: EdgeInsets.all(10),
        child: ClipOval(
            child: Material(
                color: toRender.color, // button color
                child: InkWell(
                  splashColor: toRender.color, // inkwell color
                  child: SizedBox(width: 70, height: 70,
                    child: Icon(toRender.icon, color: Colors.white, size: 30,),
                  ),
                  onTap: () async {
                    var selectedCategory = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoryTabPageView()),
                    );
                    if (selectedCategory != null) {
                      setState(() {
                        record.category = selectedCategory;
                      });
                    }
                  },
                )
            )
        )
    );
  }

  Widget _getTextField() {
    return Expanded(
        child: Container(
          margin: EdgeInsets.all(10),
          child: TextFormField(
              onChanged: (text) {
                setState(() {
                  record.title = text;
                });
              },
              initialValue: record.title,
              style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.black
              ),
              decoration: InputDecoration(
                  hintText: "Record name  (optional)".i18n,
                  border: OutlineInputBorder()
              )),
        ));
  }

  Widget _getFormLabel(String labelText, {topMargin: 14.0}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, topMargin, 14, 14),
        child: Text(labelText, style: Body1Style, textAlign: TextAlign.left),
      ),
    );
  }

  saveRecord() async {
    if (record.id == null) {
      await database.addRecord(record);
    } else {
      await database.updateRecordById(record.id, record);
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _getAppBar() {
    return AppBar(
        title: Text('Edit record'.i18n),
        actions: <Widget>[
          Visibility(
              visible: widget.passedRecord != null,
              child: IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete'.i18n, onPressed: () async {
                  AlertDialogBuilder deleteDialog = AlertDialogBuilder("Critical action".i18n)
                      .addSubtitle("Do you really want to delete this record?".i18n)
                      .addTrueButtonName("Yes".i18n)
                      .addFalseButtonName("No".i18n);

                  var continueDelete = await showDialog(context: context, builder: (BuildContext context) {
                    return deleteDialog.build(context);
                  });

                  if (continueDelete) {
                      await database.deleteRecordById(record.id);
                      Navigator.pop(context);
                  }
                }
              )
          ),
          IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save'.i18n, onPressed: () async {
                if (_formKey.currentState.validate()) {
                  await saveRecord();
                }
              }
          )]
    );
  }

  Widget _getForm() {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.all(10),
        child:  Column(
            children: [
              _getFormLabel("How much?".i18n),
              Row(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(12, 12, 20, 12),
                      child: Text(currency, style: Body1Style, textAlign: TextAlign.left),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                        autofocus: record.value == null,
                        keyboardType: TextInputType.number,
                        onChanged: (text) {
                          var numericValue = double.tryParse(text);
                          if (numericValue != null) {
                            numericValue = numericValue.abs();
                            if (record.category.categoryType == CategoryType.expense) {
                              // value is an expenses, needs to be negative
                              numericValue = numericValue * -1;
                            }
                            record.value = numericValue;
                          }
                        },
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Please enter a value";
                          }
                          var numericValue = double.tryParse(value);
                          if (numericValue == null) {
                            return "Please enter a numeric value";
                          }
                          return null;
                        },
                        initialValue: record.value != null ? record.value.abs().toString() : "",
                        style: TextStyle(
                            fontSize: 22.0,
                            color: Colors.black
                        ),
                        decoration: InputDecoration(
                            hintText: "42",
                            labelText: 'Value',
                            border: OutlineInputBorder(),
                            errorStyle: TextStyle(
                              fontSize: 16.0,
                            ),
                        )),
                  )
                ],
              ),
              _getFormLabel("When?".i18n, topMargin: 30.0),
              Row(children: <Widget>[
                Expanded(
                  child: OutlineButton(
                    onPressed: () async {
                      DateTime result = await showDatePicker(context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1970), lastDate: DateTime(2050));
                      if (result != null) {
                        setState(() {
                          record.dateTime = result;
                        });
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          getDateStr(record.dateTime),
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                    borderSide: BorderSide(color: Colors.grey, width: 0),
                  ))
              ],),
              _getFormLabel("How?".i18n, topMargin: 30.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        onChanged: (text) {
                          setState(() {
                            record.description = text;
                          });
                        },
                        initialValue: record.description,
                        style: TextStyle(
                            fontSize: 22.0,
                            color: Colors.black
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            labelText: 'Description'.i18n,
                            border: OutlineInputBorder()
                        )),
                  )
                ],
              ),
            ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        type: MaterialType.transparency,
        child: Column(
          children: <Widget>[
            _getAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(child: _createCategoryCirclePreview()),
                        Container(child: _getTextField()),
                      ],
                    ),
                    _getForm(),
                  ]
                ),
              ),
            ),
          ],
        ));
  }
}