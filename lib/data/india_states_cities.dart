// ─── Offline Dataset: Indian States & Union Territories with Major Cities ─────
// Bundled locally to avoid external API calls, rate limits, and latency.

class IndiaGeoData {
  static const Map<String, List<String>> statesAndCities = {
    'Andaman and Nicobar Islands': [
      'Port Blair', 'Car Nicobar', 'Diglipur', 'Mayabunder', 'Rangat'
    ],
    'Andhra Pradesh': [
      'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool',
      'Rajahmundry', 'Tirupati', 'Kakinada', 'Kadapa', 'Anantapur',
      'Eluru', 'Vizianagaram', 'Ongole', 'Machilipatnam', 'Chittoor'
    ],
    'Arunachal Pradesh': [
      'Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila', 'Tezu'
    ],
    'Assam': [
      'Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon',
      'Tinsukia', 'Tezpur', 'Bongaigaon', 'Dhubri', 'Karimganj'
    ],
    'Bihar': [
      'Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia',
      'Darbhanga', 'Bihar Sharif', 'Arrah', 'Begusarai', 'Katihar', 'Chhapra', 'Munger'
    ],
    'Chandigarh': [
      'Chandigarh'
    ],
    'Chhattisgarh': [
      'Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Rajnandgaon',
      'Raigarh', 'Jagdalpur', 'Ambikapur', 'Dhamtari'
    ],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'Daman', 'Diu', 'Silvassa'
    ],
    'Delhi': [
      'New Delhi', 'North Delhi', 'South Delhi', 'East Delhi',
      'West Delhi', 'Central Delhi', 'North East Delhi', 'North West Delhi',
      'South East Delhi', 'South West Delhi', 'Shahdara'
    ],
    'Goa': [
      'Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda', 'Bicholim'
    ],
    'Gujarat': [
      'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar',
      'Jamnagar', 'Junagadh', 'Gandhinagar', 'Anand', 'Navsari',
      'Morbi', 'Nadiad', 'Bharuch', 'Porbandar', 'Vapi', 'Mehsana'
    ],
    'Haryana': [
      'Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar',
      'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani'
    ],
    'Himachal Pradesh': [
      'Shimla', 'Dharamshala', 'Mandi', 'Solan', 'Baddi', 'Kullu', 'Hamirpur', 'Bilaspur'
    ],
    'Jammu and Kashmir': [
      'Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Kathua', 'Udhampur', 'Sopore'
    ],
    'Jharkhand': [
      'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro Steel City',
      'Deoghar', 'Hazaribagh', 'Giridih', 'Ramgarh', 'Phusro'
    ],
    'Karnataka': [
      'Bengaluru', 'Mysuru', 'Hubballi-Dharwad', 'Mangaluru', 'Belagavi',
      'Kalaburagi', 'Davanagere', 'Ballari', 'Vijayapura', 'Shivamogga',
      'Tumakuru', 'Udupi', 'Hassan', 'Bidar', 'Hosapete'
    ],
    'Kerala': [
      'Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam',
      'Kannur', 'Alappuzha', 'Kottayam', 'Palakkad', 'Manjeri', 'Thalassery'
    ],
    'Ladakh': [
      'Leh', 'Kargil'
    ],
    'Lakshadweep': [
      'Kavaratti', 'Agatti', 'Amini', 'Andrott'
    ],
    'Madhya Pradesh': [
      'Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain',
      'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Murwara (Katni)', 'Singrauli'
    ],
    'Maharashtra': [
      'Mumbai', 'Pune', 'Nagpur', 'Thane', 'Pimpri-Chinchwad',
      'Nashik', 'Kalyan-Dombivli', 'Vasai-Virar', 'Aurangabad (Chhatrapati Sambhajinagar)',
      'Navi Mumbai', 'Solapur', 'Mira-Bhayandar', 'Bhiwandi', 'Amravati',
      'Nanded', 'Kolhapur', 'Akola', 'Panvel', 'Sangli', 'Jalgaon'
    ],
    'Manipur': [
      'Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur'
    ],
    'Meghalaya': [
      'Shillong', 'Tura', 'Jowai', 'Nongpoh'
    ],
    'Mizoram': [
      'Aizawl', 'Lunglei', 'Champhai', 'Saiha'
    ],
    'Nagaland': [
      'Dimapur', 'Kohima', 'Mokokchung', 'Tuensang'
    ],
    'Odisha': [
      'Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur',
      'Puri', 'Balasore', 'Bhadrak', 'Baripada', 'Jharsuguda'
    ],
    'Puducherry': [
      'Puducherry', 'Karaikal', 'Mahe', 'Yanam'
    ],
    'Punjab': [
      'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda',
      'Mohali (SAS Nagar)', 'Hoshiarpur', 'Pathankot', 'Moga', 'Phagwara'
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Kota', 'Bikaner', 'Ajmer',
      'Udaipur', 'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar', 'Pali', 'Sri Ganganagar'
    ],
    'Sikkim': [
      'Gangtok', 'Namchi', 'Gyalshing', 'Mangan'
    ],
    'Tamil Nadu': [
      'Tiruppur', 'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli',
      'Salem', 'Erode', 'Vellore', 'Tirunelveli', 'Thothukudi',
      'Thanjavur', 'Dindigul', 'Karur', 'Kanchipuram', 'Nagercoil',
      'Hosur', 'Cuddalore', 'Kumbakonam', 'Tiruvannamalai'
    ],
    'Telangana': [
      'Hyderabad', 'Warangal', 'Nizamabad', 'Khammam', 'Karimnagar',
      'Ramagundam', 'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Suryapet'
    ],
    'Tripura': [
      'Agartala', 'Dharmanagar', 'Udaipur', 'Kailasahar'
    ],
    'Uttar Pradesh': [
      'Kanpur', 'Lucknow', 'Ghaziabad', 'Agra', 'Varanasi',
      'Meerut', 'Prayagraj', 'Noida', 'Bareilly', 'Aligarh',
      'Moradabad', 'Saharanpur', 'Gorakhpur', 'Jhansi', 'Mathura',
      'Muzaffarnagar', 'Ayodhya', 'Firozabad', 'Loni'
    ],
    'Uttarakhand': [
      'Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur', 'Rishikesh'
    ],
    'West Bengal': [
      'Kolkata', 'Howrah', 'Asansol', 'Siliguri', 'Durgapur',
      'Bardhaman', 'Malda', 'Baharampur', 'Habra', 'Kharagpur', 'Shantipur'
    ],
  };

  static List<String> get states => statesAndCities.keys.toList()..sort();

  static List<String> getCities(String state) {
    if (!statesAndCities.containsKey(state)) return [];
    final cities = List<String>.from(statesAndCities[state]!);
    cities.sort();
    return cities;
  }
}
