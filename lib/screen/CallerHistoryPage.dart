import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CallerHistoryPage extends StatefulWidget{
  const CallerHistoryPage({super.key});
  State<CallerHistoryPage> createState()=>_CallerHistoryPageState();
}
class _CallerHistoryPageState extends State<CallerHistoryPage>{
  Widget build(BuildContext context){
    return Scaffold(body: Center(child: Text("This is CallerHistory Page")),);
  }
}