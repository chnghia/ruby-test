class Passenger
  include DataMapper::Resource

  has n, :bookings

  Passenger.property(:phonenum, Text, :required => true, :key => true)
  Passenger.property(:password, Text, :required => true)
  Passenger.property(:created_at, DateTime)
  Passenger.property(:updated_at, DateTime)

  def to_json(*a)
   {
      'phonenum' => self.phonenum,
      'password' => self.password,
      'date'     => self.updated_at
   }.to_json(*a)
  end
end

class Booking
  include DataMapper::Resource

  belongs_to :passenger

  Booking.property(:id, Serial)
  Booking.property(:drivernum, Text)
  Booking.property(:drivername, Text)
  Booking.property(:lat, Float)
  Booking.property(:long, Float)
  Booking.property(:created_at, DateTime)
  Booking.property(:updated_at, DateTime)

  def to_json(*a)
   {
      'id'        => self.id,
      'drivernum' => self.drivernum,
      'drivername' => self.drivername,
      'passenger' => self.passenger,
      'date'      => self.updated_at
   }.to_json(*a)
  end
end
