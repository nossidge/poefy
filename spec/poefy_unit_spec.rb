#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################

describe Poefy::Poem, "-- Unit tests" do

  describe "#transform_input_regex" do

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
        ["['(?=^[A-Z])(?=^[^eE]*$)', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$']",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', 4: '^[^eE]*$', 5: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{0: '^[^eE]*$', 1: '(?=^[A-Z])(?=^[^eE]*$)'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', 5: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>nil,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 4: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>nil,
            3=>nil,
            4=>/^[^eE]*$/,
            5=>nil
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', -1: '^[^eE]*$', -2: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{7: \'^\S+$\'}',
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

  describe "#transform_input_syllable" do

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
      normal_input = [
        [0,
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        [10,
          {1=>10,2=>10,3=>10,4=>10,5=>10}],
        ['0',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['10',
          {1=>10,2=>10,3=>10,4=>10,5=>10}],
        ['99',
          {1=>99,2=>99,3=>99,4=>99,5=>99}],
        ['8,9,10',
          {1=>[8,9,10],2=>[8,9,10],3=>[8,9,10],4=>[8,9,10],5=>[8,9,10]}],
        ['6,7,8,9',
          {1=>[6,7,8,9],2=>[6,7,8,9],3=>[6,7,8,9],4=>[6,7,8,9],5=>[6,7,8,9]}],
        ['[10]',
          {1=>10,2=>0,3=>0,4=>0,5=>0}],
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
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['{o:1,e:2}',
          {1=>1,2=>2,3=>1,4=>2,5=>1}],
        ['{o:1,0:9}',
          {1=>1,2=>9,3=>1,4=>9,5=>1}],
        ['{o:1,e:2,0:9}',
          {1=>1,2=>2,3=>1,4=>2,5=>1}],
        ['{o:8,e:6,-2:6,-1:4}',
          {1=>8,2=>6,3=>8,4=>6,5=>4}],
        ['{o:8,e:6,-2:6,-1:4,0:9}',
          {1=>8,2=>6,3=>8,4=>6,5=>4}],
        ['8-10',
          {1=>[8,9,10],2=>[8,9,10],3=>[8,9,10],4=>[8,9,10],5=>[8,9,10]}],
        ['6-9',
          {1=>[6,7,8,9],2=>[6,7,8,9],3=>[6,7,8,9],4=>[6,7,8,9],5=>[6,7,8,9]}],
        ['4-9',
          { 1=>[4,5,6,7,8,9],
            2=>[4,5,6,7,8,9],
            3=>[4,5,6,7,8,9],
            4=>[4,5,6,7,8,9],
            5=>[4,5,6,7,8,9]}],
        ['4,6,8-10,12',
          { 1=>[4,6,8,9,10,12],
            2=>[4,6,8,9,10,12],
            3=>[4,6,8,9,10,12],
            4=>[4,6,8,9,10,12],
            5=>[4,6,8,9,10,12]}],
        ['[4,6,8-10,12]',
          {1=>4,2=>6,3=>[8,9,10],4=>12,5=>0}],
        ['{e:"4,6,8-10,12"}',
          {1=>0,2=>[4,6,8,9,10,12],3=>0,4=>[4,6,8,9,10,12],5=>0}],
        ['{0:6,-1:6-10}',
          {1=>6,2=>6,3=>6,4=>6,5=>[6,7,8,9,10]}],
        ['{0:4-6,-1:6-10}',
          {1=>[4,5,6],2=>[4,5,6],3=>[4,5,6],4=>[4,5,6],5=>[6,7,8,9,10]}],
        ['{e:4-6,-1:6-10}',
          {1=>0,2=>[4,5,6],3=>0,4=>[4,5,6],5=>[6,7,8,9,10]}],
        ['[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[[8-9],[8-9],[4-6],[4-6],[8-9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[[8,9],[8,9],4-6,4-6,[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[8-9,8-9,4-6,4-6,8-9]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{0:11,3m0:30}',
          {1=>11,2=>11,3=>30,4=>11,5=>11}],
        ['{0:11,3m0:30,3m1:31}',
          {1=>31,2=>11,3=>30,4=>31,5=>11}],
        [{0=>11,'3m0'=>30,'3m1'=>31},
          {1=>31,2=>11,3=>30,4=>31,5=>11}]
      ]
      weird_input = [
        ['40xxxx',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['{3: 4 5}',
          {1=>0,2=>0,3=>4,4=>0,5=>0}],
        ['{}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{xxxxx: 8}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{xxxxx: 8000}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{2m12: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{1m0: 9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{-1m0: 9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{-1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{-1m1: -9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{10: 2}',
          {1=>0,2=>0,3=>0,4=>0,5=>0,10=>2}],
        ['{0:1, 0:2, 0:3, 0:4, 0:5, 0:6, 0:7, 0:8, 0:9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{1: -12}',
          {1=>12,2=>0,3=>0,4=>0,5=>0}],
        ['{-12: -12}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['1: 12}',
          {1=>12,2=>0,3=>0,4=>0,5=>0}],
        ['1: 12',
          {1=>1,2=>1,3=>1,4=>1,5=>1}],
        ['40    ',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['    40',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['{1m1: 9}    ',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['    {1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,5]]]]]',
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5]}],
        ['[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,999,[1,2,3,4,5]]]]]',
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5,999]}],
        [[10],
          {1=>10,2=>0,3=>0,4=>0,5=>0}],
        [[8,8,5,5,8],
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        [[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,999,[1,2,3,4,5]]]]],
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5,999]}]
      ]
      error_input = [
        'x',
        'xxxx',
        'xxxx40',
        'xx40xx',
        '<40xxxx></40xxxx>',
        '{1: 12',
        '{xxxxx}',
        '{{xxxxx}}',
        '{xxxxx: xxxxx}',
        '{2: f}',
        '{3: }',
        '{3: 4: 5}',
        '{xxxxx: 8000, 0: xxxxx: 8000}',
        '{40}',
        '{[40]}',
        '{{40}}',
        '{{}}'
      ]
      describe "normal input" do
        normal_input.each do |pair|
          it "syllable: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_syllable(pair.first, 'aabba')
            again = obj.transform_input_syllable(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "weird (but technically fine) input" do
        weird_input.each do |pair|
          it "syllable: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_syllable(pair.first, 'aabba')
            again = obj.transform_input_syllable(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "error input" do
        error_input.each do |i|
          it "syllable: #{i}" do
            rhyme = obj.tokenise_rhyme('aabba')
            expect {
              obj.transform_input_syllable(i, 'aabba')
            }.to raise_error(Poefy::SyllableError)
          end
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
