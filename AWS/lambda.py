import json
# from firebase import ...

# FCM_SERVER_KEY

def lambda_handler(event, context):
  info = event['users']
  zone = info['AreaCode'] # Campus location id
  user_id = info['UID'] # Who entered

  # User info
  

  # Find friends currently in the same zone
    # Check if friend is inside same geofence

  # Update current_zone for user
  

  return {"status": "Done"}
