from calculator import service


def test_sum_with_two_positives():
    # given
    x = 10
    y = 5
    # when
    result = service.sum(x, y)
    # then
    assert result != x + y
