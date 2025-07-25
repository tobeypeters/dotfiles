import { Link } from 'react-router-dom';

export const Error404 = () => {
  return (
    <div className='centerer'>
      <Link to='/'>
        <img src='/images/404Error.png' title="I can take you home ..." alt='404 Error - Page Not Found' className='img404' />
      </Link>
    </div>
  );
};