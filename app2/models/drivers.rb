require 'logger'
require 'faster_haversine'

log = Logger.new(STDOUT)

class Driver
  include DataMapper::Resource

  Driver.property(:id, Serial, :required => true, :key => true)
  Driver.property(:name, Text, :required => true)
  Driver.property(:phonenum, Text, :required => true)
  Driver.property(:lat, Float, :required => true)
  Driver.property(:long, Float, :required => true)
  Driver.property(:created_at, DateTime)
  Driver.property(:updated_at, DateTime)

  def self.findClosest(lat, long)
    closest = 0
    drivers = Driver.all().to_a

    drivers.each_index do |i|
      new_dist = FasterHaversine.distance(lat.to_f, long.to_f, drivers[i].lat.to_f, drivers[i].long.to_f)
        
      if new_dist < FasterHaversine.distance(lat.to_f, long.to_f, drivers[closest].lat.to_f, drivers[closest].long.to_f)
        closest = i
      end
    end

    return drivers[closest]
  end


  def to_json(*a)
   {
      'id'       => self.id,
      'name'     => self.name,
      'phonenum' => self.phonenum,
      'lat'      => self.lat,
      'long'     => self.long,
      'date'     => self.updated_at
   }.to_json(*a)
  end
end

