# Leaderboard setup (Firebase, free Spark plan)

1. Firebase console -> create a project (stay on the Spark plan, add no billing).
2. Add an Android app with package `com.fahadapps.desi_business_empire`.
   Download `google-services.json` into `android/app/`.
   (Android builds without this file; the leaderboard just says it cannot connect.)
3. Build -> Authentication -> Sign-in method -> turn on **Anonymous**.
4. Build -> Firestore Database -> create (production mode), then Rules ->
   paste `firestore.rules` from the repo root -> Publish.
5. The first time the board is read, Firestore asks for an index on
   `players.netWorth` (descending). Single-field indexes are automatic, so
   no manual index is needed.

How it works: the game sends the empire name, net worth and card once a day
on the first launch, or when the player taps "Update my score" (one hour
apart). The board reads the top 50, cached for ten minutes. Free quota:
20,000 writes and 50,000 reads a day.
