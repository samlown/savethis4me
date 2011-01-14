#
# Perform filter effects to images
#
# Instanciate with an image file, specify the actions to perform, and activate.
#
# Must be used with File object, *NOT* Tempfile.
#
class MagickImageProcessor

  attr_accessor :image, :name
  attr_accessor :format

  attr_reader :source_file

  attr_reader :filters
  protected :filters

  # Create an archive image processor object using the provided source
  def initialize(options = {})
    raise "Missing source file" unless options[:source_file]
    if options[:source_file].is_a? String
      @source_file = File.open(options[:source_file])
    else
      @source_file = options[:source_file]
    end
    @filters = [ ]
    self.name = ""
  end

  def add_filter(name, options = {})
    return if name.to_s.empty? || !respond_to?(name.to_sym)
    # remove old entry
    if old = self.filters.assoc(name.to_sym)
      self.filters.delete(old)
    end
    self.filters << [name.to_sym, (options || {}).symbolize_keys]
  end

  # Execute and write the file either to file object of path
  def write(file)
    execute
    self.image.format = format
    self.image.write(file) 
  end

  # Go through each filter
  def execute
    self.image = Magick::Image.read(source_file).first
    raise "Unable to load image" if self.image.nil?
    self.format = self.image.format if self.format.to_s.empty?
    filters.each do |f|
      (filter, options) = f
      puts "Performing filter: #{filter} opts: #{options.inspect}"
      if respond_to?(filter)
        self.image = send(filter, image, options)
      end
    end
  rescue ::Magick::ImageMagickError => e
    raise "Failed to perform RMagick operations: #{e}"
  end


  protected

  # FILTERS

  def resize_to_fit(img, options)
    return img unless check_within_limits([options[:width], options[:height]])
    img2 = img.resize_to_fit(options[:width].to_i, options[:height].to_i)
    img2
  end

  alias_method :resize, :resize_to_fit

  def crop(img, options)
    return img unless check_within_limits([options[:x], options[:y]], 0)
    return img unless check_within_limits([options[:width], options[:height]])
    img2 = img.crop(options[:x].to_i, options[:y].to_i, options[:width].to_i, options[:height].to_i)
    img2
  end

  def border(img, options = {})
    options.reverse_merge!({
      :color => 'grey40',
      :width => 1,
    })
    return img unless check_within_limits(options[:width], 1, 10)
    return img if options[:color] =~ /^(grey[1-9]0|black|\#[\dA-F]{6})$/i
    border = Magick::Draw.new
    border.stroke(options[:color])
    border.stroke_width(options[:width].to_i)
    border.fill('transparent')
    border.rectangle(0, 0, img.columns - 1, img.rows - 1)
    border.draw(img)
    img
  end

  def drop_shadow(img, options = {})

    distance = (options[:distance] || 8).to_i
    blur = (options[:blur] || 4).to_i
    density = (options[:density] || 65).to_i
    angle = (options[:angle] || 315).to_i

    return img unless check_within_limits(distance, 1, 10)
    return img unless check_within_limits(blur, 1, 30)
    return img unless check_within_limits(density, 1, 100)
    return img unless check_within_limits(angle, 0, 360)

    rangle = angle * Math::PI / 180 # convert to radians
    bw = 6 # Gap for blur effect

    x = img.columns
    y = img.rows

    # Based on the distance specified, calculate the x and y distances to move by.
    dist_x = (Math::sin(rangle) * distance).abs.round
    dist_y = (Math::cos(rangle) * distance).abs.round
    if angle < 90
      dist_x = -dist_x
    elsif angle < 180
      dist_y = dist_y
      dist_x = dist_x
    elsif angle < 270
      dist_y = -dist_y
    else
      dist_x = -dist_x
      dist_y = -dist_y
    end

    # Create a new image for the background
    b_w = x + (bw * 2)
    b_h = y + (bw * 2)
    background = Magick::Image.new(b_w, b_h) do
      self.transparent_color = "white" # "transparent"
    end

    # Add a grey box for the base of the shadow
    shadow = Magick::Draw.new
    shadow.fill('black')
    shadow.fill_opacity("#{density}%")
    shadow.rectangle(bw, bw, x + bw, y + bw)
    shadow.draw(background)
    background = background.blur_image(0, blur)

    # Calculate distance to move shadow and image
    dist_x = dist_x + bw
    dist_y = dist_y + bw
    bm_x = 0
    bm_y = 0
    new_x = b_w
    new_y = b_h

    if dist_x < 0 # too far left
      bm_x = dist_x.abs
      new_x += bm_x 
      move_x = 0
    elsif dist_x > (bw * 2) # too far right
      new_x += dist_x.abs
    end
    if dist_y < 0 # too far up 
      bm_y = dist_y.abs
      new_y += bm_y 
      dist_y = 0
    elsif dist_y > (bw * 2) # too far down
      new_y += dist_y.abs
    end

    # Crop (larger) the background image, and position shadow
    background = background.extent(new_x, new_y, -bm_x, -bm_y)

    # Add white background to background where image will go
    box = Magick::Draw.new
    box.fill('white')
    box.rectangle(dist_x, dist_y, dist_x + x -1, dist_y + y - 1)
    box.draw(background)

    # Add the image to the background
    background.composite!(img, dist_x, dist_y, Magick::OverCompositeOp)
    
    # Free up any memory used
    img.destroy!

    background
  end


  def check_within_limits(values, min = 10, max = 1000)
    win = true
    win = false if values.to_s.empty?
    (values.is_a?(Array) ? values : [values]).each do |v|
      win = false if v.to_i > max
      win = false if v.to_i < min
    end
    puts "Invalid dimensions provided" unless win
    win
  end

end
