import 'package:chitchat/colors.dart';
import 'package:chitchat/screen/signup.dart';
import 'package:flutter/material.dart';

class loginPage extends StatefulWidget {
  @override
  State<loginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<loginPage> {
  var showPassword = true;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: mq.width,
            height: mq.height,
            color: !isDarkMode ? kPrimaryColor : kContentColorDarkTheme,
            child: Padding(
              padding: EdgeInsets.only(top: mq.height*0.07, left: 20),
              child: Text(
                'Welcome Back\nLogin',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: kContentColorLightTheme,
                  fontWeight: FontWeight.bold,
                  fontSize: mq.width * 0.08,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top:mq.height * 0.2<0?0:mq.height*0.2),
            child: Container(
              width: mq.width,
              height: mq.height*0.7<0?0:mq.height*0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // BorderRadius.only(
                //   topLeft: Radius.circular(20),
                //   topRight: Radius.circular(20),
                // ),
                color: isDarkMode ? Colors.black45 : kContentColorLightTheme,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(top: 30, left: 16, right: 16),
                  child: Form(
                    child:  Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: "Email",
                              suffixIcon: Icon(Icons.email_outlined,
                                  color:
                                  isDarkMode ? Colors.white : Colors.black),
                            ),
                          ),
                          SizedBox(height: 30), // Add spacing
                          TextFormField(
                            obscureText: showPassword, // Hide input for password
                            decoration: InputDecoration(
                              labelText: "Password",
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                  icon: Icon(
                                    !showPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color:
                                    isDarkMode ? Colors.white : Colors.black,
                                  )),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            child: Text("Forget Password?"),
                            alignment: Alignment.bottomRight,
                          ),
                          SizedBox(height: 24), // Add spacing
                          ElevatedButton(
                            onPressed: () {
                              // Implement login action
                            },
                            child: Center(
                                child: Text(
                                  'Login',
                                  style:
                                  Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: isDarkMode
                                        ? kContentColorDarkTheme
                                        : kContentColorLightTheme,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ),
                          SizedBox(
                            height: mq.height*0.03,
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                    color: isDarkMode
                                        ? kContentColorLightTheme
                                        : kPrimaryColor,
                                  )),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 5),
                                child: Text('Or Login with'),
                              ),
                              Expanded(
                                  child: Divider(
                                    color: isDarkMode
                                        ? kContentColorLightTheme
                                        : kPrimaryColor,
                                  ))
                            ],
                          ),
                          SizedBox(
                            height: mq.height * 0.008,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                splashColor: isDarkMode?Colors.white:Colors.grey,
                                onTap: (){},
                                child: Image(width: 25,image:AssetImage('assets/icon/google.png',)),
                              ),
                              InkWell(
                                child: CircleAvatar(
                                    child: Image(width: 30,image:AssetImage('assets/icon/facebook.png',)),
                                    backgroundColor: Colors.transparent
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: mq.height * 0.12,
                          ),
                          Align(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Don't have Account!"),
                                  InkWell(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>signUp()));
                                    },
                                    child: Text(
                                      "Create Account",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  )
                                ]),
                            alignment: Alignment.bottomRight,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}