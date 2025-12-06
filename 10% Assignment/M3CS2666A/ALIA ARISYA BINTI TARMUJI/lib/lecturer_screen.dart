import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class LecturerHome extends StatefulWidget {
  const LecturerHome({super.key});

  @override
  State<LecturerHome> createState() => _LecturerHomeState();
}

class _LecturerHomeState extends State<LecturerHome> {
  int selectedIndex = 0;

  bool isSidebarOpen = true;
  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  final testController = TextEditingController();
  final assignmentController = TextEditingController();
  final projectController = TextEditingController();
  final studentIdController = TextEditingController();

  final studentNameController = TextEditingController();
  final studentEmailController = TextEditingController();
  final studentPasswordController = TextEditingController();

  // ----------------------------------------------------
  // SUBMIT MARKS USING STUDENT ID (NOT UID)
  // ----------------------------------------------------
  Future<void> submitMarks() async {
    String studentId = studentIdController.text.trim();

    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Student ID')),
      );
      return;
    }

    try {
      // Step 1: search user by STUDENT ID field
      QuerySnapshot studentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('ID', isEqualTo: studentId)
          .get();

      if (studentQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student ID not found')),
        );
        return;
      }

      // Step 2: get the UID of student
      String studentUID = studentQuery.docs.first.id;

      // Step 3: submit marks using UID
      await FirebaseFirestore.instance
          .collection('carryMarks')
          .doc(studentUID)
          .set({
        'studentID': studentId,
        'test': int.tryParse(testController.text) ?? 0,
        'assignment': int.tryParse(assignmentController.text) ?? 0,
        'project': int.tryParse(projectController.text) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marks Submitted Successfully')),
      );

      testController.clear();
      assignmentController.clear();
      projectController.clear();
      studentIdController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ----------------------------------------------------
  // CREATE STUDENT
  // ----------------------------------------------------
  Future<void> createStudent() async {
    String name = studentNameController.text.trim();
    String email = studentEmailController.text.trim();
    String password = studentPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').add({
        'name': name,
        'email': email,
        'password': password,
        'role': 'student',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student Created Successfully')),
      );

      studentNameController.clear();
      studentEmailController.clear();
      studentPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ----------------------------------------------------
  // SIDEBAR
  // ----------------------------------------------------
  Widget sidebar() {
    return Container(
      width: 210,
      color: Colors.deepPurpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          if (isMobile(context))
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => isSidebarOpen = false),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Lecturer Menu",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          menuItem(Icons.person_add, "Create Student", 0),
          menuItem(Icons.checklist, "Submit Marks", 1),
          divider(),
          menuItem(Icons.person, "Profile", 2),
          menuItem(Icons.settings, "Settings", 3),
          menuItem(Icons.help_outline, "Help", 4),
          divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget menuItem(IconData icon, String text, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      selected: selectedIndex == index,
      selectedTileColor: Colors.deepPurple,
      onTap: () => setState(() {
        selectedIndex = index;
        if (isMobile(context)) isSidebarOpen = false;
      }),
    );
  }

  Widget divider() => const Divider(color: Colors.white38, thickness: 1);

  Widget mainContent() {
    switch (selectedIndex) {
      case 0:
        return createStudentForm();
      case 1:
        return submitMarksForm();
      default:
        return simplePage("Page Coming Soon...");
    }
  }

  Widget simplePage(String text) {
    return Center(
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 22)),
    );
  }

  // ----------------------------------------------------
  // FORMS
  // ----------------------------------------------------
  Widget createStudentForm() {
    return formContainer(
      children: [
        const Text("Create Student",
            style: TextStyle(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 20),
        textField(studentNameController, "Student Name"),
        textField(studentEmailController, "Email"),
        textField(studentPasswordController, "Password", obscure: true),
        const SizedBox(height: 20),
        actionButton("Create Student", createStudent),
      ],
    );
  }

  Widget submitMarksForm() {
    return formContainer(
      children: [
        const Text("Submit Marks",
            style: TextStyle(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 20),
        textField(studentIdController, "Student ID"), // UPDATED
        textField(testController, "Test (20%)", type: TextInputType.number),
        textField(assignmentController, "Assignment (10%)",
            type: TextInputType.number),
        textField(projectController, "Project (20%)",
            type: TextInputType.number),
        const SizedBox(height: 20),
        actionButton("Submit Marks", submitMarks),
      ],
    );
  }

  // Reusable UI
  Widget formContainer({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget textField(TextEditingController c, String label,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  Widget actionButton(String text, Function() onPress) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isMobile(context)
          ? AppBar(
              backgroundColor: Colors.deepPurple,
              title: const Text("Lecturer Home",
                  style: TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () =>
                    setState(() => isSidebarOpen = !isSidebarOpen),
              ),
            )
          : null,
      body: Row(
        children: [
          if (isSidebarOpen) sidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6A1B9A),
                    Color(0xFF4A148C),
                    Color(0xFF283593),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 1000),
                    padding: const EdgeInsets.only(bottom: 40),
                    child: mainContent(),
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
