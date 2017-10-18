#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################

describe Poefy::Poem, "-- Unit tests" do

  describe "#transform_string_regex" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticForms
        include Poefy::StringManipulation
        include Poefy::HandleError
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
        ["['(?=^[A-Z])(?=^[^eE]*$)','^[^eE]*$','^[^eE]*$','^[^eE]*$','^[^eE]*$']",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1=>'(?=^[A-Z])(?=^[^eE]*$)',2=>'^[^eE]*$',3=>'^[^eE]*$',4=>'^[^eE]*$',5=>'^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{0=>'^[^eE]*$',1=>'(?=^[A-Z])(?=^[^eE]*$)'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1=>'(?=^[A-Z])(?=^[^eE]*$)',2=>'^[^eE]*$',3=>'^[^eE]*$',5=>'^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>nil,
            5=>/^[^eE]*$/
          }],
        ["{1=>'(?=^[A-Z])(?=^[^eE]*$)',4=>'^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>nil,
            3=>nil,
            4=>/^[^eE]*$/,
            5=>nil
          }],
        ["{1=>'(?=^[A-Z])(?=^[^eE]*$)',2=>'^[^eE]*$',3=>'^[^eE]*$',-1=>'^[^eE]*$',-2=>'^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{7=>\'^\S+$\'}',
          {
            1=>nil,
            2=>nil,
            3=>nil,
            4=>nil,
            5=>nil,
            7=>/^\S+$/
          }],
        ['rgegerg',
          {
            1=>/rgegerg/,
            2=>/rgegerg/,
            3=>/rgegerg/,
            4=>/rgegerg/,
            5=>/rgegerg/
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

  describe "private method #poetic_form_from_text" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticFormFromText
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end

    it "'80' should rhyme with 'weighty'" do
      lines = ["Lorem ipsum dolor weighty", "Lorem ipsum dolor 80"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'80' should not rhyme with 'shoe'" do
      lines = ["Lorem ipsum dolor shoe", "Lorem ipsum dolor 80"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
    it "'2' should rhyme with 'shoe'" do
      lines = ["Lorem ipsum dolor shoe", "Lorem ipsum dolor 2"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'2' should not rhyme with 'weighty'" do
      lines = ["Lorem ipsum dolor weighty", "Lorem ipsum dolor 2"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
    it "'wind' should rhyme with 'sinned'" do
      lines = ["A mighty wind", "A whitey sinned"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'wind' should rhyme with 'mind'" do
      lines = ["A mighty wind", "A flighty mind"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'wind' should not rhyme with 'drunk'" do
      lines = ["A mighty wind", "A fighty drunk"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
  end

end

################################################################################
