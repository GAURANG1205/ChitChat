import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StoryPagescreen extends StatefulWidget{
  const StoryPagescreen({super.key});
  State<StoryPagescreen> createState()=>_StoryPageScreenState();
}
class _StoryPageScreenState extends State<StoryPagescreen>{
  Widget build(BuildContext context){
    return const Scaffold(body: Center(child: Text("This is Story Page")),);
  }
}