# Define Earth's radius in meters
BEGIN {
  R = 6371000 # Radius in meters
  pi = 3.14159265358979323846 # Value of pi
}

# Function to convert degrees to radians
function radians(deg) {
  return deg * pi / 180
}

# Process each line of the input file
{
  lat1 = $1
  lon1 = $2
  lat2 = $3
  lon2 = $4

  # Convert degrees to radians
  lat1_rad = radians(lat1)
  lon1_rad = radians(lon1)
  lat2_rad = radians(lat2)
  lon2_rad = radians(lon2)

  # Calculate the difference in latitudes and longitudes
  dLat = lat2_rad - lat1_rad
  dLon = lon2_rad - lon1_rad

  # Apply the Haversine formula
  a = (sin(dLat/2))^2 + cos(lat1_rad) * cos(lat2_rad) * (sin(dLon/2))^2
  c = 2 * atan2(sqrt(a), sqrt(1-a))
  distance = R * c

  # Print the calculated distance
  printf "%i\n", distance
} 
