require 'rubygems'
require 'EventTree.rb'
require 'Generators.rb'
require 'ChaosComposer.rb'
require 'fileutils'

include Generators

gem 'midilib', '= 1.0.0'
require 'midilib/sequence'
require 'midilib/consts'
include MIDI

def relative_pitch_changes(guide)
    previous = name_to_midi(guide.shift[1])
    _return = []
    guide.each do |g|
      new_val = name_to_midi(g[1])
      _return << (previous - new_val).abs
      previous = new_val
    end
    _return
end

def relative_rhythm_changes(guide)
    seq = Sequence.new()
    previous = seq.note_to_delta(guide.shift[0])
    _return = []
    guide.each do |g|
      new_val = seq.note_to_delta(g[0])
      _return << (previous - new_val).abs
      previous = new_val
    end
    _return
end

def absolute_pitch_frequency(guide)
  histo = {}
  guide.each do |g|
    histo[g[1]] ||= 0
    histo[g[1]] += 1
  end
  order_histogram(histo)
end

def scale_positions(guide)
  histo = {}
  guide.each do |g|
    i = note_to_scale_pos(g[1])
    histo[i] ||= 0
    histo[i] += 1
  end
  histo
end

def order_histogram(histo)
  master_scale = ChaosComposer.master_scale
  ordered_histo = []
  master_scale.each{ |note| ordered_histo << (histo[note] || 0) }
  master_scale.zip(ordered_histo)
end

def chromatic_pitch_frequency(guide)
  histo = {}
  guide.each do |g|
    i = g[1].gsub(/\d/,'')
    histo[i] ||= 0
    histo[i] += 1
  end
  histo
end


@@name_to_midi = {}
ChaosComposer::master_scale.each_with_index do |name, index|
 @@name_to_midi[name] = index + 24
end 

def name_to_midi(note_name)
  return @@name_to_midi[note_name]
end

def write_track(filename, guide)
  seq = Sequence.new()

  # Create a first track for the sequence. This holds tempo events and stuff
  # like that.
  track = Track.new(seq)
  seq.tracks << track
  track.events << Tempo.new(Tempo.bpm_to_mpq(120))
  track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')

  # Create a track to hold the notes. Add it to the sequence.
  track = Track.new(seq)
  seq.tracks << track

  # Give the track a name and an instrument name (optional).
  track.name = 'X track'
  track.instrument = GM_PATCH_NAMES[0]

  # Add a volume controller event (optional).
  track.events << Controller.new(0, CC_VOLUME, 127)

  track.events << ProgramChange.new(0, 1, 0)
  
  
  guide.each  do |g|
     track.events << NoteOnEvent.new(0, name_to_midi(g[1]), 127, 0)
     track.events << NoteOffEvent.new(0, name_to_midi(g[1]), 127, seq.note_to_delta(g[0]))
  end
  
  
   File.open(filename, 'w') { | file |
      seq.write(file)
    }
end

def write_note_list(filename, guide)
  seq=Sequence.new
  
  File.open(filename, 'w') do |f|
    start = 0
    guide.each do |g|
      new_val = seq.note_to_delta(g[0])
      f << "Note #{start} #{start+new_val} #{name_to_midi(g[1])}\n"
      start += new_val
    end
  end
 
end

@scale_positions = ['1', 'b2', '2', 'b3', '3', '4', 'b5', '5', 'b6', '6', 'b7', '7']

def note_to_scale_pos(note)
  key = ChaosComposer.master_scale.zip(@scale_positions * ChaosComposer.octaves)
  i = ChaosComposer.master_scale.index(note)
  key[i][1]
end 

def avg_data_set(guide, control, method, run)
  
   guide_analysis = send(method,guide)
   control_analysis = send(method,control)
   
   line1 = "#{method.gsub(/_/,' ')} Control Run: #{run}, #{control_analysis.join(',')}"
   line2 = "#{method.gsub(/_/,' ')} Event Tree Run: #{run}, #{guide_analysis.join(',')}"
   
   return "#{line1}\n#{line2}\n"
end

def histo_data_set(guide, control, method)

  control_data = "#{method.gsub(/_/,' ')} Control\n"
  send(method,control).each do |data|
    control_data += "#{data[0]},#{data[1]}\n"
  end
  
  exp_data = "#{method.gsub(/_/,' ')} Event Tree\n"
  send(method,guide).each do |data|
    exp_data += "#{data[0]},#{data[1]}\n"
  end

  return "#{control_data}\n#{exp_data}"
end


#major scale
@root_scale = [1,0,1,0,1,1,0,1,0,1,0,1]


########
#  Main
#    equation_name - one of ['Rossler', 'Henon', 'Lorenz', 'Chua']  
#
#    takes equation name and invokes Chaoscomposer with the data
#    from the equation.
#
#    composition takes the model of an experiment where
#     N is the number of notes generated in the melody and
#     runs is the number of melodies to generate
#     ** for each "run" of chaotic compositions, a "control"
#     counterpart is created using random chance so we can
#     evaluate if our models/methods are better than random..

def main(equation_name)
  runs = 10
  n = 100

  klass = Object.const_get(equation_name)
  
  control_runs = klass::compose_runs(runs,n,ChaosComposer.master_scale.size)
  experiment_runs = klass::raw_compose_runs(runs,n)

  @test = klass.to_s.split('::')[1].downcase! 


  FileUtils.mkdir_p("data/#{@test}/midi")
  FileUtils.mkdir_p("data/#{@test}/note_list")
  File.open("data/#{@test}_data_set.csv", 'w') do |f|
    all_controls = []
    all_experiments = []

    runs.times do |index|
        
        control = ChaosComposer::control(control_runs[index])
        guide = ChaosComposer::compose(experiment_runs[index], @root_scale)
        
        if(index % 3 == 0)
          write_track("data/#{@test}/midi/#{@test}_control_run_#{index}.mid", control)
          write_track("data/#{@test}/midi/#{@test}_event_tree_run_#{index}.mid",guide)
          write_note_list("data/#{@test}/note_list/#{@test}_control_run_#{index}.note_list", control)
          write_note_list("data/#{@test}/note_list/#{@test}_event_tree_run_#{index}.note_list",guide)
        end
        f << avg_data_set(guide, control, 'relative_pitch_changes', index)
        f << avg_data_set(guide, control, 'relative_rhythm_changes', index)
        all_controls += control
        all_experiments += guide
    end
    
    f << histo_data_set(all_experiments, all_controls, 'absolute_pitch_frequency')
    f << histo_data_set(all_experiments, all_controls, 'scale_positions')
    
    f.close()
  end
end


# process shell input

if __FILE__ == $0
        
  tests = ['Rossler', 'Henon', 'Lorenz', 'Chua']  

  if( tests.include? ARGV[0] )
     main(ARGV[0])
  else
     puts "Must include name of which chaotic equation to use. 
           Usage:   ruby Driver.rb <#{tests.join(', ')}>
           Ex:      ruby Driver.rb Henon".gsub(/^\s*/,'')

     exit(1)
  end

end

