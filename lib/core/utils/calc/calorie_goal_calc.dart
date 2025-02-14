
class CalorieGoalCalc {
  static double getDailyKcalLeft(
          double totalKcalGoal, double totalKcalIntake) =>
      totalKcalGoal - totalKcalIntake;

  static double getTotalKcalGoal(
          double userKcalGoal, double totalKcalActivities) =>
      // Simply use the user's goal plus any activities
      userKcalGoal + totalKcalActivities;
}
