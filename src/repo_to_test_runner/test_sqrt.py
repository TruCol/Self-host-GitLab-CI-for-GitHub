import pytest

from solve_sqrt import Main
#import calc_sqrt

def test_sqrt():
    main = Main()
    assert main.calc_sqrt(9) == 3
    
