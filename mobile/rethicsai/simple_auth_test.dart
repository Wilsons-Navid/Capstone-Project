// Simple validation test without Flutter dependencies
void main() {
  print('🧪 Testing RethicsAI Authentication System...\n');
  
  // Test email validation
  testEmailValidation();
  
  // Test password validation
  testPasswordValidation();
  
  // Test form validation
  testFormValidation();
  
  print('\n✅ All authentication validation tests passed!');
  print('🔥 Ready to test Firebase authentication in the app!');
}

void testEmailValidation() {
  print('📧 Testing email validation...');
  
  // Valid emails
  assert(isValidEmail('test@example.com') == true, 'Valid email should pass');
  assert(isValidEmail('user@domain.co.uk') == true, 'Valid email with co.uk should pass');
  assert(isValidEmail('user.name@example.org') == true, 'Valid email with dot should pass');
  
  // Invalid emails
  assert(isValidEmail('invalid-email') == false, 'Invalid email should fail');
  assert(isValidEmail('test@') == false, 'Email without domain should fail');
  assert(isValidEmail('@domain.com') == false, 'Email without username should fail');
  assert(isValidEmail('') == false, 'Empty email should fail');
  
  print('   ✅ Email validation tests passed');
}

void testPasswordValidation() {
  print('🔒 Testing password validation...');
  
  // Valid passwords (6+ characters)
  assert(isValidPassword('password123') == true, 'Valid password should pass');
  assert(isValidPassword('123456') == true, 'Six character password should pass');
  assert(isValidPassword('abcdefg') == true, 'Seven character password should pass');
  
  // Invalid passwords (less than 6 characters)
  assert(isValidPassword('12345') == false, 'Five character password should fail');
  assert(isValidPassword('abc') == false, 'Three character password should fail');
  assert(isValidPassword('') == false, 'Empty password should fail');
  
  print('   ✅ Password validation tests passed');
}

void testFormValidation() {
  print('📝 Testing form validation...');
  
  // Test empty fields
  assert(validateForm('', 'password') == 'Email is required', 'Empty email should return error');
  assert(validateForm('test@example.com', '') == 'Password is required', 'Empty password should return error');
  
  // Test invalid data
  assert(validateForm('invalid-email', 'password') == 'Invalid email format', 'Invalid email should return error');
  assert(validateForm('test@example.com', '123') == 'Password must be at least 6 characters', 'Short password should return error');
  
  // Test valid data
  assert(validateForm('test@example.com', 'password123') == null, 'Valid form should pass');
  assert(validateForm('user@domain.org', '123456') == null, 'Valid form should pass');
  
  print('   ✅ Form validation tests passed');
}

// Helper functions (same logic as in the app)
bool isValidEmail(String email) {
  return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

String? validateForm(String email, String password) {
  if (email.isEmpty) {
    return 'Email is required';
  }
  
  if (!isValidEmail(email)) {
    return 'Invalid email format';
  }
  
  if (password.isEmpty) {
    return 'Password is required';
  }
  
  if (!isValidPassword(password)) {
    return 'Password must be at least 6 characters';
  }
  
  return null; // No errors
}