class ApiEndpoint {
  static const String baseUrl = 'https://leadmantracrm.com/api/mobile';

  // Auth
  static const String login = '$baseUrl/login';
  static const String deleteAccount = '$baseUrl/delete-account';

  // Leads
  static const String createLead = '$baseUrl/leads';
  static const String syncLeads  = '$baseUrl/leads/sync';
  static const String leadsList  = '$baseUrl/leads/list';
  static String updateLead(int id) => '$baseUrl/leads/$id';

  // Calendar
  static const String dropdowns       = '$baseUrl/dropdowns';
  static const String calendarGrid    = '$baseUrl/calendar';
  static const String calendarNotes   = '$baseUrl/calendar/notes';
  static String calendarNote(int id)       => '$baseUrl/calendar/notes/$id';
  static String calendarNoteDelete(int id) => '$baseUrl/calendar/notes/$id/delete';
}
