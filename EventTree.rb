module EventTree
 @@DEBUG = false
  
 ##constructor.  creates a new NoteEvent with a raw 'note' value, level, 
 #boolean whether it is a majorevent or not, and an array of subevents.
 #adding events to subevents creates the tree structure
 class NoteEvent
  attr_accessor :note, :level, :subevents, :scale, :major, :parent, :pitch, :length
  def initialize(note, level, major, subevents = [])
    @note = note
    @level = level
    @major = major
    @subevents = subevents || []
    @scale = []
    @pitch = 'none'
  end
  
  #to string
  def to_s
    "Level: #{@level} Note: #{@note} Children:#{!@subevents.empty?} Scale:#{@scale.join(',')} Pitch:#{self.real_pitch}"
    #print_array(@subevents) if ! subevents.empty?
  end
  
  #gets root of tree
  def root
    if @parent
      return @parent.root
    else
      return self
    end
  end

 #these methods access the highest-level values
 #for the given class attribute
  def real_scale
    if @parent
      return @parent.real_scale
    else
      return @scale
    end
  end

  def real_pitch
    if @parent
      return @parent.real_pitch
    else
      return @pitch
    end
  end
  
  def real_level
    if @parent
      return @parent.real_level
    else
      return @level
    end
  end
  
  #sets the scale to all ancestors
  def scale=(other)
    if @parent && major
      @scale=other
      @parent.scale = other
    else
      @scale=other
    end
  end
  
  #finds the index of the major event within @subevents
  #counts from the right to make sure its the last highest value
  def self.major_event_index(current_group)
      highest_value = current_group.sort{ |a,b| a.note <=> b.note }
      highest_value = highest_value.last.note
      index = current_group.length - 1
      while(current_group[index].note != highest_value) do
        index = index - 1
      end
    index
  end
  
  #wrapper method for finding self's major_event index
  def me_index
    NoteEvent::major_event_index(@subevents)
  end
  
  #gets the major event in the subevents
  def major_event
    if @subevents.empty? 
      false
    else
      @subevents[self.me_index]
    end
  end
  
  def events_before_major
    if @subevents.empty? 
      false
    else
      @subevents[0...(me_index)]
    end
  end
  
  def events_after_major
    if @subevents.empty? 
      false
    else
      @subevents[(me_index+1)...@subevents.length]
    end
  end
  
  #create a new_majar event, used in build_tree
  #to create new root nodes
  def self.new_major(current_group)
    index = self.major_event_index(current_group)
    current_group[index].major = true
    major_event = current_group[index].dup
    major_event.level += 1
    major_event.subevents = current_group
    current_group[index].parent = major_event
    return major_event
  end
end

#given an array of NoteEvents, recursively
#generate a tree with new levels of major 
#events
def self.build_tree(_events)
  
  _notes = _events.collect{|event|event.note}
  print_array(_notes) if @@DEBUG

  previous_note = -1000
  motion = 'nothing'
  previous_motion = 'nothing'
  current_group = []
  events = []
  major_events = []
  
  _events.each_with_index do |e, index|
  
    
    if(e.note > previous_note)
      motion = 'increasing'
    elsif(e.note == previous_note)
      motion = previous_motion
    else
      motion = 'decreasing'
    end
  
     puts e.note if @@DEBUG
     puts motion if @@DEBUG
 
    if(previous_motion == 'decreasing' && motion == 'increasing')
      puts "cutting"  if @@DEBUG
      
      puts "create major event" if @@DEBUG
      print_array(current_group) if @@DEBUG
      major_events << NoteEvent.new_major(current_group)

      current_group = [e]
    else
      current_group << e
    end
  
    previous_motion = motion
    previous_note = e.note
  
  end #_events.each
  
  if !current_group.empty? && ! major_events.empty?
    major_events << NoteEvent.new_major(current_group)
  end
  
  #base case
  if major_events.empty?
    return NoteEvent.new_major(current_group)
  end

  return build_tree(major_events)
  
end


  def self.build_tree_from_notes(notes)
    self.build_tree(self.notes_to_events(notes))
  end

  def self.notes_to_events(notes)
    notes.collect { |note| NoteEvent.new(note,0, false) }
  end
  
  #perform an in_order, depth first traversal invoking block
  #on each element
  def self.in_order(tree, &block)
    if !tree.subevents.empty?
      tree.subevents.each{ |e| self.in_order(e,&block) }
    else
       block.call(tree)
    end
  end

  def self.collect_groups(tree, array=[])
    if(tree.real_level == 1)
      array << tree.subevents
    else
       tree.subevents.each{|e| self.collect_groups(e, array)}
    end
    return array
  end

  #turn tree into an array
  def self.linearize(tree)
    line = []
    self.in_order(tree) {|node| line << node}
    line
  end
  
end
