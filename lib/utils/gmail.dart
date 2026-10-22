final _gmail = RegExp(r'^[a-z0-9](?:[a-z0-9._]{0,62}[a-z0-9])?@gmail\.com$');

const gmailFormatHint = 'example123@gmail.com';
const gmailFormatError = 'Use a Gmail address like example123@gmail.com';

bool isGmailAddress(String value) {
  final email = value.trim().toLowerCase();
  return !email.contains('..') && _gmail.hasMatch(email);
}
