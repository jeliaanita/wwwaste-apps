import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(GetMaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[100],
  ),
  home: PeopleList(),
));

// ============ MODELS ============
class Person {
  final String name, height, mass, gender, birthYear;
  final String url;
  final List<String> films;
  final List<String> vehicles;
  final String eyeColor, hairColor, skinColor;

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        height = json['height'] ?? '',
        mass = json['mass'] ?? '',
        gender = json['gender'] ?? '',
        birthYear = json['birth_year'] ?? '',
        url = json['url'] ?? '',
        eyeColor = json['eye_color'] ?? '',
        hairColor = json['hair_color'] ?? '',
        skinColor = json['skin_color'] ?? '',
        films = List<String>.from(json['films'] ?? []),
        vehicles = List<String>.from(json['vehicles'] ?? []);

  String get id => url.split('/').where((s) => s.isNotEmpty).last;
}

// ============ CONTROLLER ============
class PeopleController extends GetxController {
  RxList<Person> people = <Person>[].obs;
  RxBool isLoading = false.obs;
  RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPeople();
  }

  Future<void> fetchPeople() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await http.get(
        Uri.parse('https://swapi.dev/api/people/?page=1')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        people.value = results.map((p) => Person.fromJson(p)).toList();
      } else {
        error.value = 'Failed to load people';
      }
    } catch (e) {
      error.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<Person?> fetchPersonDetail(String personId) async {
    try {
      final response = await http.get(
        Uri.parse('https://swapi.dev/api/people/$personId/')
      );

      if (response.statusCode == 200) {
        return Person.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching person detail: $e');
    }
    return null;
  }
}

// ============ PEOPLE LIST SCREEN ============
class PeopleList extends StatelessWidget {
  final PeopleController controller = Get.put(PeopleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Star Wars People'),
        elevation: 2,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.people.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty && controller.people.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(controller.error.value),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchPeople,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchPeople,
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: controller.people.length,
            itemBuilder: (context, index) {
              final person = controller.people[index];
              return PersonCard(person: person);
            },
          ),
        );
      }),
    );
  }
}

// ============ PERSON CARD WIDGET ============
class PersonCard extends StatelessWidget {
  final Person person;

  const PersonCard({Key? key, required this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Get.to(() => PeopleDetail(personId: person.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  person.name[0],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.height,
                          label: '${person.height}cm',
                        ),
                        SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.monitor_weight_outlined,
                          label: '${person.mass}kg',
                        ),
                        SizedBox(width: 8),
                        _InfoChip(
                          icon: person.gender == 'male' 
                              ? Icons.male 
                              : person.gender == 'female'
                                  ? Icons.female
                                  : Icons.person,
                          label: person.gender.toUpperCase(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ PEOPLE DETAIL SCREEN ============
class PeopleDetail extends StatelessWidget {
  final String personId;
  final PeopleController controller = Get.find<PeopleController>();

  PeopleDetail({Key? key, required this.personId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Person Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: FutureBuilder<Person?>(
        future: controller.fetchPersonDetail(personId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load person details'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final person = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            person.name[0],
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          person.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Physical Attributes
                _DetailSection(
                  title: 'Physical Attributes',
                  children: [
                    _DetailRow('Height', '${person.height} cm', Icons.height),
                    _DetailRow('Mass', '${person.mass} kg', Icons.monitor_weight_outlined),
                    _DetailRow('Gender', person.gender.toUpperCase(), Icons.person),
                    _DetailRow('Eye Color', person.eyeColor, Icons.remove_red_eye),
                    _DetailRow('Hair Color', person.hairColor, Icons.face),
                    _DetailRow('Skin Color', person.skinColor, Icons.palette),
                  ],
                ),
                SizedBox(height: 16),

                // Additional Info
                _DetailSection(
                  title: 'Additional Information',
                  children: [
                    _DetailRow('Birth Year', person.birthYear, Icons.cake),
                    _DetailRow('Films', '${person.films.length}', Icons.movie),
                    _DetailRow('Vehicles', '${person.vehicles.length}', Icons.directions_car),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}