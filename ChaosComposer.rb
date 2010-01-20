module ChaosComposer
  
  OCTAVES = 4
  @@notes = %w{C C#/Db D D#/Eb E F F#/Gb G G#/Ab A A#/Bb B}
  @@note_lengths = %w{sixteenth dotted_sixteenth eighth dotted_eighth quarter dotted_quarter half dotted_half whole}

  @@master_scale = []
  OCTAVES.times do |i|
      @@master_scale << @@notes.collect{ |n| "#{n.gsub(/[:alpha:]\#\//,'')}#{i+1}"}
  end
  @@master_scale.flatten!
  
  def self.octaves
    OCTAVES
  end
  
  def self.master_scale
    @@master_scale
  end

  def self.compose(notes, scale)
    tree = EventTree::build_tree_from_notes(notes)
    self.make_melody(tree, scale)
    self.make_rhythm(tree)
    events = EventTree::linearize(tree)
    events.collect{|e| e.length}.zip(events.collect{|e| e.pitch})
  end

  def self.make_rhythm(tree)
  
    events = EventTree::linearize(tree)
    

    previous_motion = 'nothing'
    previous_note = events.first.note
    index = rand(@@note_lengths.size) / 2
    direction = 1

    events.each do |e|

        if(e.major)

          if(e.note > previous_note)
            motion = 'increasing'
          elsif(e.note < previous_note)
            motion = 'decreasing'
          else
            motion = previous_motion
          end

          previous_note = e.note
          previous_motion = motion

          if(motion == 'increasing')
            #incrase by integer
            index = (index + (rand(e.real_level)+1) * 2)
            index = @@note_lengths.size - 1 if index >= @@note_lengths.size
          else
            #divide by integer
            denom = (rand(e.real_level) + 1) * 2
            index = (index - denom) if (index - denom) > 0 
            index = rand(@@note_lengths.size) if index == 0
          end

          constant = rand(3) == 0
          direction = rand(2) == 0 ? -1 : 1
        end

        if(constant)
           e.length = @@note_lengths[index]
        else
           e.length = @@note_lengths[index]
           direction *= -1 if !(0...@@note_lengths.size).include?(index + direction)
           index = (index + direction) 
         end
      end
  end
  
  
  def self.sub_scale(scale, level)
    new_scale = [1] + scale.map{ |note| note == 0 ? 0 : (rand(2) == 1  || rand(2) == 1) ? 1 : 0 }[1...scale.length]
    #new_scale = scale.map{ |note| note == 0 ? 0 : (rand(2) == 1  || rand(2) == 1) ? 1 : 0 }
    #scale[0] = 1 if( !scale.index(1) )
    if(level > 0) 
      self.sub_scale(new_scale, level-1)
    else 
      return new_scale
    end
  end

  def self.assign_scales(tree, root_scale)
    events = EventTree::linearize(tree)
    events.each do |e|
      e.scale = self.sub_scale(root_scale, e.real_level)
    end
  end

  def self.scale_to_notes(scale)
    (scale*OCTAVES).zip(@@master_scale).reject{ |p| p[0] == 0 }.collect{|p| p[1]}
  end

  def self.make_melody(tree, root_scale)
    assign_scales(tree, root_scale)
    recurse_melody(tree)
  end


  def self.get_note(scale, reference, offset)
    pairs = (scale*OCTAVES).zip(@@master_scale)
    pairs.reject!{ |p| p[0] == 0 }
    start = pairs.index([1,reference])
    real = (start + offset) * OCTAVES/2 % pairs.size
    pairs[real][1]
  end

  def self.get_note2(scale)
     notes = scale_to_notes(scale)
     notes[rand(notes.size)] + ''
  end

  def self.recurse_melody(node)
    if(node.subevents.empty?)
      return 
    else
      before = node.events_before_major
      after = node.events_after_major

      major_event = node.major_event

      reference_pitch = get_note2(major_event.scale)
      node.pitch = reference_pitch
      major_event.pitch = reference_pitch

      if(before)
        pitch_change = rand(13) - 6  #(-12..12)
        before.each_with_index do |e, index|
          mult = before.size - index #count backwards
          scale = or_scales(e.scale,node.scale)
          e.pitch = get_note(scale, reference_pitch, pitch_change*mult)
        end
      end

      if(after)
        pitch_change = rand(13) - 6  #(-12..12)
        after.each_with_index do |e,index |
          scale = or_scales(e.scale,node.scale)
          e.pitch = get_note(scale, reference_pitch, pitch_change*(index+1))
        end
      end

      before.each{ |e| self.recurse_melody(e)} if (before)
      self.recurse_melody(major_event)
      after.each{ |e| self.recurse_melody(e)} if (after)
    end
  end

  def self.or_scales(scale1, scale2)
    scale1.zip(scale2).collect do |pair|
      pair[0] == 1 || pair[1] == 1 ? 1 : 0
    end
  end

  def self.and_scales(scale1, scale2)
    scale1.zip(scale2).collect do |pair|
      pair[0] == 1 && pair[1] == 1 ? 1 : 0
    end
  end

  def self.control(notes)
    guide = []
    notes.each do |note|
      pitch = @@master_scale[note % @@master_scale.size]
      duration = @@note_lengths[note % @@note_lengths.size]
      guide << [duration, pitch]
    end
    guide
  end
  
end


#  def collapse_scales(events, &block)
#    if(events.size > 0)
#      return events.inject(events.first.scale) {|sum, e| sum = block.call(sum, e.scale) }
#    else 
#      return false
#    end
#  end

#  def collapse_scales2(events, &block)
#    if(events.size > 0)
#      return events.inject(events.first) {|sum, e| sum = block.call(sum, e) }
#    else 
#      return false
#    end
#  end