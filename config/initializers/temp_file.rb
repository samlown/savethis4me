
require 'tempfile'

class Tempfile
  def make_tmpname(basename, n)
    'tmp%d_%d_%s' % [$$, n, basename]
  end

  def to_file
    @tmpfile
  end
end
