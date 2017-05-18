#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################

describe Poefy::PoefyGen do

  before(:all) do
    @root = File.expand_path('../../', __FILE__)
    db_file = "#{@root}/data/spec_test_tiny.db"
    File.delete(db_file) if File.exists?(db_file)
  end
  after(:all) do
    db_file = "#{@root}/data/spec_test_tiny.db"
    File.delete(db_file) if File.exists?(db_file)
  end

  describe "using tiny dataset spec_test_tiny.db / spec_test_tiny.txt" do

    file_txt = "spec_test_tiny.txt"
    file_db  = "spec_test_tiny.db"

    before(:each) do
      @poefy = Poefy::PoefyGen.new(file_db, { proper: false })
    end
    after(:each) do
      @poefy.close
    end
    it "initialised object not nil" do
      expect(@poefy).to_not be_nil
    end

    describe "#make_database( '#{@root}/data/#{file_txt}', true )" do
      it "should make the database '#{@root}/data/#{file_db}" do
        db_file = "#{@root}/data/#{file_db}"
        @poefy.make_database "#{@root}/data/#{file_txt}", true
        expect(@poefy.db.exists?).to be true
        expect(File.exists?(db_file)).to be true
      end
    end

    describe ":rhyme option" do

      describe "should return nil" do
        it "({  })" do
          poem = @poefy.poem
          expect(poem).to be_nil
        end
        it "({ rhyme: nil })" do
          poem = @poefy.poem ({ rhyme: nil })
          expect(poem).to be_nil
        end
        it "({ rhyme: ' ' })" do
          poem = @poefy.poem ({ rhyme: ' ' })
          expect(poem).to be_nil
        end
        it "({ rhyme: '' })" do
          poem = @poefy.poem ({ rhyme: '' })
          expect(poem).to be_nil
        end
      end

      describe "should return correct number of lines" do
        rhymes = %w{a b z A aa ab zz AA AB AA1 A1 B1 Z1 AB1 A1A1A1A1B1B1B1B1B1}
        rhymes += ['A1A1A1 A1A1A1 B1B1B1B1B1B1','a b c a b c']
        rhymes += ['   abc','abc   ','   abc   ']
        rhymes += ['n   aaa   n','n   aXXXa   N1']
        rhymes.each do |i|
          it "({ rhyme: '#{i}' })" do
            poem = @poefy.poem ({ rhyme: i })
            expect(poem.count).to be i.gsub(/[0-9]/,'').length
          end
        end
      end

      describe "should accept characters other than number" do
        rhymes = %w{. , : .. ., ,, :: (()) @ ~ <<>< A1A1A1...a;}
        rhymes.each do |i|
          it "({ rhyme: '#{i}' })" do
            poem = @poefy.poem ({ rhyme: i })
            expect(poem.count).to be i.gsub(/[0-9]/,'').length
          end
        end
      end

      describe "should be nil if can't parse rhyme string" do
        rhymes = %w{a1 b1 ab1 Ab1 AAAAABb1 1 1111 1122 11221 ;;::1. }
        rhymes += ['AA Bb1','11 11','11 1 1','..1.']
        rhymes.each do |i|
          it "({ rhyme: '#{i}' })" do
            poem = @poefy.poem ({ rhyme: i })
            expect(poem).to be_nil
          end
        end
      end

      describe "should be nil if can't complete rhyme string" do
        rhymes = %w{aaaaaa abcd aaaaabbbbb}
        rhymes.each do |i|
          it "({ rhyme: '#{i}' })" do
            poem = @poefy.poem ({ rhyme: i })
            expect(poem).to be_nil
          end
        end
      end

      describe "should correctly repeat uppercase lines" do
        lines = 200
        it "({ rhyme: 'A' * #{lines} })" do
          poem = @poefy.poem ({ rhyme: 'A' * lines })
          expect(poem.count).to be lines
          expect(poem.uniq.count).to be 1
        end
        it "({ rhyme: ('A'..'C').to_a.map { |i| i * #{lines} }.join })" do
          rhyme = ('A'..'C').to_a.map { |i| i * lines }.join
          poem = @poefy.poem ({ rhyme: rhyme })
          expect(poem.count).to be lines * 3
          expect(poem.uniq.count).to be 3
        end
      end

      describe "should be nil if can't complete repeating rhyme string" do
        lines = 200
        it "({ rhyme: ('A'..'D').to_a.map { |i| i * #{lines} }.join })" do
          rhyme = ('A'..'D').to_a.map { |i| i * lines }.join
          poem = @poefy.poem ({ rhyme: rhyme })
          expect(poem).to be_nil
        end
      end

    end

    describe ":form option" do

      describe "should return correct number of lines" do
        it "({ form: :default })" do
          poem = @poefy.poem ({ form: :default })
          expect(poem.count).to be 1
        end
      end

      describe "should be nil if given a named form it can't fulfil" do
        it "({ form: 'sonnet' })" do
          poem = @poefy.poem ({ form: 'sonnet' })
          expect(poem).to be_nil
        end
        it "({ form: :villanelle })" do
          poem = @poefy.poem ({ form: :villanelle })
          expect(poem).to be_nil
        end
      end

      describe "should be nil if given a junk named form" do
        it "({ form: 'sonnet_junk' })" do
          poem = @poefy.poem ({ form: 'sonnet_junk' })
          expect(poem).to be_nil
        end
        it "({ form: :not_a_form })" do
          poem = @poefy.poem ({ form: :not_a_form })
          expect(poem).to be_nil
        end
        it "({ form: :not_a_form, indent: '0010' })" do
          poem = @poefy.poem ({ form: :not_a_form, indent: '0010' })
          expect(poem).to be_nil
        end
      end

      describe "should be valid if given a junk named form, and a rhyme" do
        it "({ form: :not_a_form, rhyme: 'abcb' })" do
          poem = @poefy.poem ({ form: :not_a_form, rhyme: 'abcb' })
          expect(poem.count).to be 4
        end
      end

      describe "should overwrite a named form if another option is specified" do
        it "({ form: 'default', rhyme: 'ab' })" do
          poem = @poefy.poem ({ form: 'default', rhyme: 'ab' })
          expect(poem.count).to be 2
        end
        it "({ form: :villanelle, rhyme: 'abcb' })" do
          poem = @poefy.poem ({ form: :villanelle, rhyme: 'abcb' })
          expect(poem.count).to be 4
        end
      end
    end
  end

  ##############################################################################

  describe "using dataset shakespeare.db / shakespeare_sonnets.txt" do

    file_txt = "shakespeare_sonnets.txt"
    file_db  = "shakespeare.db"

    # All the Shakespeare lines are pentameter, so some forms should fail.
    forms      = Poefy::PoeticForms::POETIC_FORMS
    forms_fail = [:limerick, :haiku, :common, :ballad]
    forms_pass = forms.keys - forms_fail

    before(:each) do
      @poefy = Poefy::PoefyGen.new(file_db, { proper: false })
    end

    it "initialised object not nil" do
      expect(@poefy).to_not be_nil
    end

    describe "#make_database( '#{@root}/data/#{file_txt}', true )" do
      it "should make the database '#{@root}/data/#{file_db}" do
        db_file = "#{@root}/data/#{file_db}"
#        File.delete(db_file) if File.exists?(db_file)
        input = `sed '/[a-z]/!d' #{@root}/data/#{file_txt}`
        @poefy.make_database input
        expect(@poefy.db.exists?).to be true
        expect(File.exists?(db_file)).to be true
      end
    end

    describe "using form string" do
      describe "should return correct number of lines" do

        # Make sure each form's lines match the expected output.
        # Generate a few to be sure.
        forms_pass.each do |form|
          it "({ form: #{form} })" do
            10.times do
              poem = @poefy.poem ({ form: form })
              expect(poem.count).to satisfy do |c|
                [*forms[form][:rhyme]].map do |r|
                  r.gsub(/[0-9]/,'').length
                end.include?(c)
              end
            end
          end
        end
      end

      describe "should fail to be created" do
        forms_fail.each do |form|
          it "({ form: #{form} })" do
            4.times do
              poem = @poefy.poem ({ form: form })
              expect(poem).to be_nil
            end
          end
        end
      end
    end
  end

  ##############################################################################

  describe "using dataset whitman.db / whitman_leaves.txt" do

    file_txt = "whitman_leaves.txt"
    file_db  = "whitman.db"

    # There's a good mix of syllable count, so all forms should pass.
    forms      = Poefy::PoeticForms::POETIC_FORMS
    forms_pass = forms.keys

    before(:each) do
      @poefy = Poefy::PoefyGen.new(file_db, { proper: false })
    end

    it "initialised object not nil" do
      expect(@poefy).to_not be_nil
    end

    describe "#make_database( '#{@root}/data/#{file_txt}', true )" do
      it "should make the database '#{@root}/data/#{file_db}" do
        db_file = "#{@root}/data/#{file_db}"
#        File.delete(db_file) if File.exists?(db_file)
        input = `sed '/[a-z]/!d' #{@root}/data/#{file_txt}`
        @poefy.make_database input
        expect(@poefy.db.exists?).to be true
        expect(File.exists?(db_file)).to be true
      end
    end

    describe "using form string" do
      describe "should return correct number of lines" do

        # Make sure each form's lines match the expected output.
        # Generate a few to be sure.
        forms_pass.each do |form|
          it "({ form: #{form} })" do
            10.times do
              poem = @poefy.poem ({ form: form })
              expect(poem.count).to satisfy do |c|
                [*forms[form][:rhyme]].map do |r|
                  r.gsub(/[0-9]/,'').length
                end.include?(c)
              end
            end
          end
        end
      end
    end

    describe "using syllable string" do

      it "({ rhyme: 'abcb defe', syllable: '[8,6,8,6,0,8,6,8,6]' })" do
        options = {
          rhyme:    'abcb defe',
          syllable: '[8,6,8,6,0,8,6,8,6]'
        }
        poem = @poefy.poem (options)
        expect(poem.count).to be options[:rhyme].length
      end

      it "({ rhyme: 'abcb defe', syllable: '[8,6,8,6,8,6,8,6]' })" do
        options = {
          rhyme:    'abcb defe',
          syllable: '[8,6,8,6,8,6,8,6]'
        }
        poem = @poefy.poem (options)
        expect(poem.count).to be options[:rhyme].length
      end
    end
  end

  ##############################################################################

  describe "#transform_string_syllable" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticForms
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end
    describe "using rhyme string 'aabba'" do
      input_and_output = [
        ['10',
          {1=>10,2=>10,3=>10,4=>10,5=>10}],
        ['9,10,11',
          {1=>[9,10,11],2=>[9,10,11],3=>[9,10,11],4=>[9,10,11],5=>[9,10,11]}],
        ['[8,8,5,5,8]',
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:8,2:8,3:5,4:5,5:8}',
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['{1:8,2:8,3:5,5:8}',
          {1=>8,2=>8,3=>5,4=>0,5=>8}],
        ['{0:99,1:8,2:8,3:5,5:8}',
          {1=>8,2=>8,3=>5,4=>99,5=>8}],
        ['{1:[8,9],2:[8,9],3:[4,5,6],4:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:[8,9],2:[8,9],3:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>0,5=>[8,9]}],
        ['{0:99,1:[8,9],2:[8,9],3:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>99,5=>[8,9]}],
        ['{0:[8,9],3:[4,5,6],4:[4,5,6]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:8,5:8}',
          {1=>8,2=>0,3=>0,4=>0,5=>8}],
        ['{1:8,2:8,3:5,-2:5,-1:8}',
          {1=>8,2=>8,3=>5,4=>5,5=>8}]
      ]
      input_and_output.each do |pair|
        it "syllable: #{pair.first}" do
          rhyme = obj.tokenise_rhyme('aabba')
          out   = obj.transform_string_syllable(pair.first, 'aabba')
          again = obj.transform_string_syllable(out, 'aabba')
          expect(out).to eq pair.last
          expect(again).to eq out
          expect(again).to eq pair.last
        end
      end
    end
  end

  ##############################################################################

  describe "#transform_string_regex" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticForms
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end

    describe "using rhyme string 'aabba'" do
      input_and_output = [
        ['^[^e]*$',
          {
            1=>/^[^e]*$/,
            2=>/^[^e]*$/,
            3=>/^[^e]*$/,
            4=>/^[^e]*$/,
            5=>/^[^e]*$/
          }],
        ['[/(?=^[A-Z])(?=^[^eE]*$)/,/^[^eE]*$/,/^[^eE]*$/,/^[^eE]*$/,/^[^eE]*$/]',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{1=>/(?=^[A-Z])(?=^[^eE]*$)/,2=>/^[^eE]*$/,3=>/^[^eE]*$/,4=>/^[^eE]*$/,5=>/^[^eE]*$/}',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{0=>/^[^eE]*$/,1=>/(?=^[A-Z])(?=^[^eE]*$)/}',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{1=>/(?=^[A-Z])(?=^[^eE]*$)/,2=>/^[^eE]*$/,3=>/^[^eE]*$/,5=>/^[^eE]*$/}',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>nil,
            5=>/^[^eE]*$/
          }],
        ['{1=>/(?=^[A-Z])(?=^[^eE]*$)/,4=>/^[^eE]*$/}',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>nil,
            3=>nil,
            4=>/^[^eE]*$/,
            5=>nil
          }],
        ['{1=>/(?=^[A-Z])(?=^[^eE]*$)/,2=>/^[^eE]*$/,3=>/^[^eE]*$/,-1=>/^[^eE]*$/,-2=>/^[^eE]*$/}',
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }]
      ]
      input_and_output.each do |pair|
        it "regex: #{pair.first}" do
          out   = obj.transform_string_regex(pair.first, 'aabba')
          again = obj.transform_string_regex(out, 'aabba')
          expect(out).to eq pair.last
          expect(again).to eq out
          expect(again).to eq pair.last
        end
      end
    end
  end

end

################################################################################
