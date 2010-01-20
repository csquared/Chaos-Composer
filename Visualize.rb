 require '~/school/nova/masters_thesis/code/FractalMusic.rb'
 
 chua = Chua.standard
 notes = chua.compose(40)
 x_offset = 15 #pixels
 y_mult = 3
 x1 = x_offset
 y1 = notes.shift * y_mult


Shoes.app do
  notes.each do |note|
    nofill
    oval x1, y1, 5, 5
    x2 = x1 + x_offset
    y2 = note * y_mult
    line x1, y1, x2, y2
    x1 = x2
    y1 = y2
  end
end