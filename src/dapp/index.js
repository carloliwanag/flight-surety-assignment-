import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';

(async () => {
  let result = null;

  let contract = new Contract('localhost', () => {
    // Read transaction
    contract.isOperational((error, result) => {
      console.log(error, result);
      display('Operational Status', 'Check if contract is operational', [
        { label: 'Operational Status', error: error, value: result },
      ]);
    });

    // User-submitted transaction
    DOM.elid('submit-oracle').addEventListener('click', () => {
      let flight = DOM.elid('flight-number').value;
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        console.log(result);
        display('Oracles', 'Trigger oracles', [
          {
            label: 'Fetch Flight Status',
            error: error,
            value: result.flight + ' ' + result.timestamp,
          },
        ]);
      });
    });

    DOM.elid('flights').addEventListener('click', async () => {
      console.log('Get List');
      contract.fetchFlightsList().then((data) => {
        console.log(data);
        let displayDiv = DOM.elid('flightsList');
        let section = DOM.section();

        data.map((flightName) => {
          let row = section.appendChild(DOM.div({ className: 'row top-20' }));
          row.appendChild(DOM.div({ className: 'col-sm-4 field' }, flightName));
          row.appendChild(
            DOM.button(
              { className: 'btn btn-primary ml-3', id: 'buy-' + flightName },
              'Buy'
            )
          );
          row.appendChild(
            DOM.button(
              {
                className: 'btn btn-primary ml-3',
                id: 'submit-' + flightName,
              },
              'Submit to Oracles'
            )
          );
          section.appendChild(row);
        });

        displayDiv.append(section);
      });
    });
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid('display-wrapper');
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: 'row' }));
    row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
    row.appendChild(
      DOM.div(
        { className: 'col-sm-8 field-value' },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}
