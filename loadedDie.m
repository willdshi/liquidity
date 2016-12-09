function state = loadedDie(prob)

u = rand();
state = 1;

cProb = prob(state);
state = 1;

while u >= cProb
    state = state + 1;
    cProb = cProb + prob(state);
end