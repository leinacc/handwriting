# Minifloat

Based off https://github.com/ISSOtm/gb-starter-kit with some modifications:
* `Makefile` - added rules for generating the keras model files
* `src/include/defines.asm` - added a macro, `add_A_to_HL`

## Files of interest

* `handwriting.py` - trains the NN with a modified MNIST, whose inputs mimic the 14x14 GB grid
* `process_keras.py` - extracts the trained model and generates an asm file of tables
* `models.asm` - an example asm file output from the above extraction
* `src/predict.asm` - the main prediction algorithm
* `src/grid.asm` - grid logic
* `src/text.asm` - simple text logic, plus it loads the grid-related tiles
* `src/intro.asm` - game entry point

## Compiling

### Poetry

Building the project requires [Poetry](https://python-poetry.org/docs/). Or copy the example `model.asm` into `res/`.

### From original readme

Simply open you favorite command prompt / terminal, place yourself in this directory (the one the Makefile is located in), and run the command `make`. This should create a bunch of things, including the output in the `bin` folder.

While this project is able to compile under "bare" Windows (i.e. without using MSYS2, Cygwin, etc.), it requires PowerShell, and is sometimes unreliable. You should try running `make` two or three times if it errors out.

If you get errors that you don't understand, try running `make clean`. If that gives the same error, try deleting the `deps` folder. If that still doesn't work, try deleting the `bin` and `obj` folders as well. If that still doesn't work, you probably did something wrong yourself.
